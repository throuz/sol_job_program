import "../libraries/system_instruction.sol";

@program_id("C5Va9W4xKoXrWFjAvMgToCQpHFTN9CcJXQTLFh7yk99C")
contract solva {
  address private platformPubKey;
  address private expertPubKey;
  address private clientPubKey;
  uint64 private caseAmountLamports;
  uint64 private expertDepositLamports;
  uint64 private clientDepositLamports;
  address private indemniteePubKey;
  Status private status;

  enum Status {
    Created,
    Canceled,
    Activated,
    ForceClosed,
    Compensated,
    Completed,
    GotIncome,
    Closed
  }

  @payer(payer)
  constructor(
    address _platformPubKey,
    uint64 _caseAmountLamports,
    uint64 _expertDepositLamports,
    uint64 _clientDepositLamports
  ) {
    platformPubKey = _platformPubKey;
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
    require(clientDepositLamports == _clientDepositLamports);
    clientPubKey = tx.accounts.signer.key;
    if (clientDepositLamports > 0) {
      SystemInstruction.transfer(
        tx.accounts.signer.key, tx.accounts.DA.key, clientDepositLamports
      );
    }
    status = Status.Activated;
  }

  @mutableSigner(signer)
  function platformForceCloseCaseForExpert() external {
    require(status == Status.Activated);
    require(tx.accounts.signer.key == platformPubKey);
    indemniteePubKey = expertPubKey;
    status = Status.ForceClosed;
  }

  @mutableSigner(signer)
  function platformForceCloseCaseForClient() external {
    require(status == Status.Activated);
    require(tx.accounts.signer.key == platformPubKey);
    indemniteePubKey = clientPubKey;
    status = Status.ForceClosed;
  }

  @mutableSigner(signer)
  @mutableAccount(DA)
  function indemniteeRecieveCompensation() external {
    require(status == Status.ForceClosed);
    require(tx.accounts.signer.key == indemniteePubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.DA.lamports -= expertDepositLamports;
      tx.accounts.signer.lamports += expertDepositLamports;
    }
    if (clientDepositLamports > 0) {
      tx.accounts.DA.lamports -= clientDepositLamports;
      tx.accounts.signer.lamports += clientDepositLamports;
    }
    status = Status.Compensated;
  }

  @mutableSigner(signer)
  @mutableAccount(DA)
  @mutableAccount(expert)
  @mutableAccount(platform)
  function clientCompleteCase() external {
    require(status == Status.Activated);
    require(tx.accounts.signer.key == clientPubKey);
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
