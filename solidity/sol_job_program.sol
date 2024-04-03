import "../libraries/system_instruction.sol";

@program_id("D5Y1bmRzxQK8RSTGbxMBHkfa2DEmxZU2qcoiEX1PABeJ")
contract sol_job_program {
  address private platformPubKey;
  address private expertPubKey;
  address private clientPubKey;
  uint64 private caseAmountLamports;
  uint64 private expertDepositLamports;
  uint64 private clientDepositLamports;
  bool private isExpertGetIncome;
  bool private isExpertRedeem;
  bool private isClientRedeem;
  Indemnitee private indemnitee;
  address private indemniteePubKey;
  bool private isIndemniteeReceived;
  Status private status;

  enum Indemnitee {
    Expert,
    Client
  }

  enum Status {
    Pending,
    Cancelled,
    Active,
    Expiration,
    Completed,
    Closed,
    ForceCompleted
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
    require(tx.accounts.signer.key == expertPubKey);
    require(status == Status.Pending);
    if (expertDepositLamports > 0) {
      SystemInstruction.transfer(
        tx.accounts.dataAccount.key, expertPubKey, expertDepositLamports
      );
    }
    status = Status.Cancelled;
  }

  @mutableSigner(signer)
  function clientActiveCase(uint64 _clientDepositLamports) external {
    if (clientDepositLamports > 0) {
      require(clientDepositLamports == _clientDepositLamports);
    }
    require(status == Status.Pending);
    clientPubKey = tx.accounts.signer.key;
    if (clientDepositLamports > 0) {
      SystemInstruction.transfer(
        clientPubKey, tx.accounts.dataAccount.key, clientDepositLamports
      );
    }
    status = Status.Active;
  }

  @mutableSigner(signer)
  function clientCompleteCase() external {
    require(status == Status.Active);
    require(tx.accounts.signer.key == clientPubKey);
    SystemInstruction.transfer(
      clientPubKey, tx.accounts.dataAccount.key, caseAmountLamports
    );
    isExpertGetIncome = false;
    if (expertDepositLamports > 0) {
      isExpertRedeem = false;
    } else {
      isExpertRedeem = true;
    }
    if (clientDepositLamports > 0) {
      isClientRedeem = false;
    } else {
      isClientRedeem = true;
    }
    status = Status.Completed;
  }

  @mutableSigner(signer)
  function expertGetIncome() external {
    require(status == Status.Completed && isExpertGetIncome == false);
    require(tx.accounts.signer.key == expertPubKey);
    tx.accounts.dataAccount.lamports -= caseAmountLamports * 99 / 100;
    tx.accounts.signer.lamports += caseAmountLamports * 99 / 100;
    isExpertGetIncome = true;
  }

  @mutableSigner(signer)
  function expertRedeemDeposit() external {
    bool isCompletionAsExpected =
      status == Status.Completed && isExpertRedeem == false;
    bool isForcedCompletionAsExpected =
      status == Status.ForceCompleted && isExpertRedeem == false;
    require(isCompletionAsExpected || isForcedCompletionAsExpected);
    require(tx.accounts.signer.key == expertPubKey);
    tx.accounts.dataAccount.lamports -= expertDepositLamports;
    tx.accounts.signer.lamports += expertDepositLamports;
    isExpertRedeem = true;
  }

  @mutableSigner(signer)
  function clientRedeemDeposit() external {
    bool isCompletionAsExpected =
      status == Status.Completed && isClientRedeem == false;
    bool isForcedCompletionAsExpected =
      status == Status.ForceCompleted && isClientRedeem == false;
    require(isCompletionAsExpected || isForcedCompletionAsExpected);
    require(tx.accounts.signer.key == clientPubKey);
    tx.accounts.dataAccount.lamports -= clientDepositLamports;
    tx.accounts.signer.lamports += clientDepositLamports;
    isClientRedeem = true;
  }

  @mutableSigner(signer)
  function platformCloseCase() external {
    bool isCompletionAsExpected = status == Status.Completed
      && isExpertGetIncome && isExpertRedeem && isClientRedeem;
    bool isIndemniteeExpertAsExpected = status == Status.ForceCompleted
      && indemnitee == Indemnitee.Expert && isExpertRedeem && isIndemniteeReceived;
    bool isIndemniteeClientAsExpected = status == Status.ForceCompleted
      && indemnitee == Indemnitee.Client && isClientRedeem && isIndemniteeReceived;
    bool isForcedCompletionAsExpected =
      isIndemniteeExpertAsExpected || isIndemniteeClientAsExpected;
    require(isCompletionAsExpected || isForcedCompletionAsExpected);
    require(tx.accounts.signer.key == platformPubKey);
    if (isCompletionAsExpected) {
      tx.accounts.dataAccount.lamports -= caseAmountLamports * 1 / 100;
      tx.accounts.signer.lamports += caseAmountLamports * 1 / 100;
    }
    status = Status.Closed;
  }

  @mutableSigner(signer)
  function platformForcedCaseComplete(Indemnitee _indemnitee) external {
    require(status == Status.Active);
    require(tx.accounts.signer.key == platformPubKey);
    indemnitee = _indemnitee;
    if (indemnitee == Indemnitee.Expert) {
      isExpertRedeem = false;
      indemniteePubKey = expertPubKey;
    }
    if (indemnitee == Indemnitee.Client) {
      isClientRedeem = false;
      indemniteePubKey = clientPubKey;
    }
    isIndemniteeReceived = false;
    status = Status.ForceCompleted;
  }

  @mutableSigner(signer)
  function indemniteeReceiveCompensation() external {
    require(status == Status.ForceCompleted && isIndemniteeReceived == false);
    require(tx.accounts.signer.key == indemniteePubKey);
    if (indemnitee == Indemnitee.Expert) {
      tx.accounts.dataAccount.lamports -= clientDepositLamports;
      tx.accounts.signer.lamports += clientDepositLamports;
    }
    if (indemnitee == Indemnitee.Client) {
      tx.accounts.dataAccount.lamports -= expertDepositLamports;
      tx.accounts.signer.lamports += expertDepositLamports;
    }
    isIndemniteeReceived = true;
  }
}
