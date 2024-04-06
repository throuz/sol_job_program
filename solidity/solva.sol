import "../libraries/system_instruction.sol";

@program_id("4DN2e9zBcoCA4SWm5gVpju7hHoWB7yUBk27BTt3SNBcS")
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
  function clientCompleteCase() external {
    require(status == Status.Activated);
    require(tx.accounts.signer.key == clientPubKey);

    SystemInstruction.transfer(
      tx.accounts.signer.key, tx.accounts.DA.key, caseAmountLamports
    );
    status = Status.Completed;
  }

  @mutableAccount(signer)
  @mutableAccount(DA)
  function expertGetIncome() external {
    require(status == Status.Completed);
    require(tx.accounts.signer.key == expertPubKey);
    tx.accounts.DA.lamports -= caseAmountLamports * 99 / 100;
    tx.accounts.signer.lamports += caseAmountLamports * 99 / 100;
    if (expertDepositLamports > 0) {
      tx.accounts.DA.lamports -= expertDepositLamports;
      tx.accounts.signer.lamports += expertDepositLamports;
    }
    status = Status.GotIncome;
  }

  @mutableAccount(signer)
  @mutableAccount(DA)
  function platformCloseCase() external {
    require(status == Status.GotIncome);
    require(tx.accounts.signer.key == platformPubKey);
    tx.accounts.DA.lamports -= caseAmountLamports * 1 / 100;
    tx.accounts.signer.lamports += caseAmountLamports * 1 / 100;
    status = Status.Closed;
  }
}
