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

  enum Indemnitee {
    Expert,
    Client
  }

  enum Status {
    Pending,
    Canceled,
    Active,
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
    status = Status.Pending;
  }

  @mutableSigner(signer)
  function expertCancelCase() external {
    require(status == Status.Pending);
    require(tx.accounts.signer.key == expertPubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= expertDepositLamports;
      tx.accounts.signer.lamports += expertDepositLamports;
    }
    status = Status.Canceled;
  }

  @mutableSigner(signer)
  function clientActiveCase(uint64 _clientDepositLamports) external {
    require(status == Status.Pending);
    require(clientDepositLamports == _clientDepositLamports);
    clientPubKey = tx.accounts.signer.key;
    if (clientDepositLamports > 0) {
      SystemInstruction.transfer(
        tx.accounts.signer.key,
        tx.accounts.dataAccount.key,
        clientDepositLamports
      );
    }
    status = Status.Active;
  }

  @mutableSigner(signer)
  function platformForceCloseCaseForExpert() external {
    require(status == Status.Active);
    require(tx.accounts.signer.key == platformPubKey);
    indemniteePubKey = expertPubKey;
    status = Status.ForceClosed;
  }

  @mutableSigner(signer)
  function platformForceCloseCaseForClient() external {
    require(status == Status.Active);
    require(tx.accounts.signer.key == platformPubKey);
    indemniteePubKey = clientPubKey;
    status = Status.ForceClosed;
  }

  @mutableSigner(signer)
  function expertRecieveCompensation() external {
    require(status == Status.ForceClosed);
    require(tx.accounts.signer.key == indemniteePubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= expertDepositLamports;
      tx.accounts.signer.lamports += expertDepositLamports;
    }
    if (clientDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= clientDepositLamports;
      tx.accounts.signer.lamports += clientDepositLamports;
    }
    status = Status.Compensated;
  }

  @mutableSigner(signer)
  function clientRecieveCompensation() external {
    require(status == Status.ForceClosed);
    require(tx.accounts.signer.key == indemniteePubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= expertDepositLamports;
      tx.accounts.signer.lamports += expertDepositLamports;
    }
    if (clientDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= clientDepositLamports;
      tx.accounts.signer.lamports += clientDepositLamports;
    }
    status = Status.Compensated;
  }

  @mutableSigner(signer)
  function clientCompleteCase() external {
    require(status == Status.Active);
    require(tx.accounts.signer.key == clientPubKey);
    SystemInstruction.transfer(
      tx.accounts.signer.key,
      tx.accounts.dataAccount.key,
      caseAmountLamports - clientDepositLamports
    );
    status = Status.Completed;
  }

  @mutableSigner(signer)
  function expertGetIncome() external {
    require(status == Status.Completed);
    require(tx.accounts.signer.key == expertPubKey);
    tx.accounts.dataAccount.lamports -= caseAmountLamports * 99 / 100;
    tx.accounts.signer.lamports += caseAmountLamports * 99 / 100;
    if (expertDepositLamports > 0) {
      tx.accounts.dataAccount.lamports -= expertDepositLamports;
      tx.accounts.signer.lamports += expertDepositLamports;
    }
    status = Status.GotIncome;
  }

  @mutableSigner(signer)
  function platformCloseCase() external {
    require(status == Status.GotIncome);
    require(tx.accounts.signer.key == platformPubKey);
    tx.accounts.dataAccount.lamports -= caseAmountLamports * 1 / 100;
    tx.accounts.signer.lamports += caseAmountLamports * 1 / 100;
    status = Status.Closed;
  }
}
