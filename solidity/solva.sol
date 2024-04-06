import "../libraries/system_instruction.sol";

@program_id("C5Va9W4xKoXrWFjAvMgToCQpHFTN9CcJXQTLFh7yk99C")
contract solva {
  address private platformPubKey;
  address private expertPubKey;
  address private clientPubKey;
  uint64 private caseAmountLamports;
  uint64 private expertDepositLamports;
  uint64 private clientDepositLamports;
  Status private status;

  enum Status {
    Created,
    Canceled,
    Activated,
    ForceClosed,
    Completed
  }

  @payer(payer)
  constructor(
    address _platformPubKey,
    address _clientPubKey,
    uint64 _caseAmountLamports,
    uint64 _expertDepositLamports,
    uint64 _clientDepositLamports
  ) {
    platformPubKey = _platformPubKey;
    clientPubKey = _clientPubKey;
    expertPubKey = tx.accounts.payer.key;
    caseAmountLamports = _caseAmountLamports;
    expertDepositLamports = _expertDepositLamports;
    clientDepositLamports = _clientDepositLamports;
    if (expertDepositLamports > 0) {
      SystemInstruction.transfer(
        tx.accounts.payer.key,
        tx.accounts.dataAccount.key,
        expertDepositLamports
      );
    }
    status = Status.Created;
  }

  @mutableSigner(signer)
  @mutableAccount(DA)
  function expertCancelCase() external {
    require(status == Status.Created);
    require(tx.accounts.signer.key == expertPubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.DA.lamports -= expertDepositLamports;
      tx.accounts.signer.lamports += expertDepositLamports;
    }
    status = Status.Canceled;
  }

  @mutableSigner(signer)
  @mutableAccount(DA)
  function clientActivateCase(uint64 _clientDepositLamports) external {
    require(status == Status.Created);
    require(tx.accounts.signer.key == clientPubKey);
    require(clientDepositLamports == _clientDepositLamports);
    if (clientDepositLamports > 0) {
      SystemInstruction.transfer(
        tx.accounts.signer.key, tx.accounts.DA.key, clientDepositLamports
      );
    }
    status = Status.Activated;
  }

  @mutableSigner(signer)
  @mutableAccount(DA)
  @mutableAccount(expert)
  function platformForceCloseCaseForExpert() external {
    require(status == Status.Activated);
    require(tx.accounts.signer.key == platformPubKey);
    require(tx.accounts.expert.key == expertPubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.DA.lamports -= expertDepositLamports;
      tx.accounts.expert.lamports += expertDepositLamports;
    }
    if (clientDepositLamports > 0) {
      tx.accounts.DA.lamports -= clientDepositLamports;
      tx.accounts.expert.lamports += clientDepositLamports;
    }
    status = Status.ForceClosed;
  }

  @mutableSigner(signer)
  @mutableAccount(DA)
  @mutableAccount(client)
  function platformForceCloseCaseForClient() external {
    require(status == Status.Activated);
    require(tx.accounts.signer.key == platformPubKey);
    require(tx.accounts.client.key == clientPubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.DA.lamports -= expertDepositLamports;
      tx.accounts.client.lamports += expertDepositLamports;
    }
    if (clientDepositLamports > 0) {
      tx.accounts.DA.lamports -= clientDepositLamports;
      tx.accounts.client.lamports += clientDepositLamports;
    }
    status = Status.ForceClosed;
  }

  @mutableSigner(signer)
  @mutableAccount(DA)
  @mutableAccount(expert)
  @mutableAccount(platform)
  function clientCompleteCase() external {
    require(status == Status.Activated);
    require(tx.accounts.signer.key == clientPubKey);
    require(tx.accounts.expert.key == expertPubKey);
    require(tx.accounts.platform.key == platformPubKey);
    SystemInstruction.transfer(
      tx.accounts.signer.key,
      tx.accounts.expert.key,
      caseAmountLamports * 99 / 100
    );
    SystemInstruction.transfer(
      tx.accounts.signer.key,
      tx.accounts.platform.key,
      caseAmountLamports * 1 / 100
    );
    if (clientDepositLamports > 0) {
      tx.accounts.DA.lamports -= clientDepositLamports;
      tx.accounts.signer.lamports += clientDepositLamports;
    }
    if (expertDepositLamports > 0) {
      tx.accounts.DA.lamports -= expertDepositLamports;
      tx.accounts.expert.lamports += expertDepositLamports;
    }
    status = Status.Completed;
  }
}
