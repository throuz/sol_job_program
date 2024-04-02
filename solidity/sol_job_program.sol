import "../libraries/system_instruction.sol";

@program_id("D5Y1bmRzxQK8RSTGbxMBHkfa2DEmxZU2qcoiEX1PABeJ")
contract sol_job_program {
  address private platformPubKey;
  address private makerPubKey;
  address private takerPubKey;
  uint64 private totalLamports;
  uint64 private depositLamports;
  bool private isTakerGetIncome;
  bool private isMakerRedemption;
  bool private isTakerRedemption;
  Indemnitee private indemnitee;
  address private indemniteePubKey;
  bool private isIndemniteeReceived;
  Status private status;

  enum Indemnitee {
    Maker,
    Taker
  }

  enum Status {
    Pending,
    Taken,
    Completed,
    Closed,
    ForceCompleted
  }

  @payer(payer)
  constructor(
    address _platformPubKey,
    uint64 _totalLamports,
    uint64 _depositLamports
  ) {
    platformPubKey = _platformPubKey;
    makerPubKey = tx.accounts.payer.key;
    totalLamports = _totalLamports;
    depositLamports = _depositLamports;
    SystemInstruction.transfer(
      tx.accounts.payer.key, tx.accounts.dataAccount.key, depositLamports
    );
    status = Status.Pending;
  }

  @mutableSigner(signer)
  function takerTakeCase() external {
    require(status == Status.Pending, "NOT_ALLOW_TAKE");
    takerPubKey = tx.accounts.signer.key;
    SystemInstruction.transfer(
      takerPubKey, tx.accounts.dataAccount.key, depositLamports
    );
    status = Status.Taken;
  }

  @mutableSigner(signer)
  function makerConfirmCaseComplete() external {
    require(status == Status.Taken, "NOT_ALLOW_COMPLETE");
    require(tx.accounts.signer.key == makerPubKey, "INVALID_MAKER");
    address dataAccountPubKey = tx.accounts.dataAccount.key;
    SystemInstruction.transfer(makerPubKey, dataAccountPubKey, totalLamports);
    isTakerGetIncome = false;
    isMakerRedemption = false;
    isTakerRedemption = false;
    status = Status.Completed;
  }

  @mutableSigner(signer)
  function takerGetIncome() external {
    require(
      status == Status.Completed && isTakerGetIncome == false,
      "NOT_ALLOW_GET_INCOME"
    );
    require(tx.accounts.signer.key == takerPubKey, "INVALID_TAKER");
    tx.accounts.dataAccount.lamports -= totalLamports * 99 / 100;
    tx.accounts.signer.lamports += totalLamports * 99 / 100;
    isTakerGetIncome = true;
  }

  @mutableSigner(signer)
  function makerRedemptionDeposit() external {
    bool isCompletionAsExpected =
      status == Status.Completed && isMakerRedemption == false;
    bool isForcedCompletionAsExpected =
      status == Status.Completed && isMakerRedemption == false;
    require(
      isCompletionAsExpected || isForcedCompletionAsExpected,
      "NOT_ALLOW_REDEMPTION_DEPOSIT"
    );
    require(tx.accounts.signer.key == makerPubKey, "INVALID_MAKER");
    tx.accounts.dataAccount.lamports -= depositLamports;
    tx.accounts.signer.lamports += depositLamports;
    isMakerRedemption = true;
  }

  @mutableSigner(signer)
  function takerRedemptionDeposit() external {
    bool isCompletionAsExpected =
      status == Status.Completed && isTakerRedemption == false;
    bool isForcedCompletionAsExpected =
      status == Status.Completed && isTakerRedemption == false;
    require(
      isCompletionAsExpected || isForcedCompletionAsExpected,
      "NOT_ALLOW_REDEMPTION_DEPOSIT"
    );
    require(tx.accounts.signer.key == takerPubKey, "INVALID_TAKER");
    tx.accounts.dataAccount.lamports -= depositLamports;
    tx.accounts.signer.lamports += depositLamports;
    isTakerRedemption = true;
  }

  @mutableSigner(signer)
  function platformCloseCase() external {
    bool isCompletionAsExpected = status == Status.Completed && isTakerGetIncome
      && isMakerRedemption && isTakerRedemption;
    bool isIndemniteeMakerAsExpected = status == Status.ForceCompleted
      && indemnitee == Indemnitee.Maker && isMakerRedemption
      && isIndemniteeReceived;
    bool isIndemniteeTakerAsExpected = status == Status.ForceCompleted
      && indemnitee == Indemnitee.Taker && isTakerRedemption
      && isIndemniteeReceived;
    bool isForcedCompletionAsExpected =
      isIndemniteeMakerAsExpected || isIndemniteeTakerAsExpected;
    require(
      isCompletionAsExpected || isForcedCompletionAsExpected, "NOT_ALLOW_CLOSE"
    );
    require(tx.accounts.signer.key == platformPubKey, "INVALID_PLATFORM");
    tx.accounts.dataAccount.lamports -= totalLamports * 1 / 100;
    tx.accounts.signer.lamports += totalLamports * 1 / 100;
    status = Status.Closed;
  }

  @mutableSigner(signer)
  function platformForcedCaseComplete(Indemnitee _indemnitee) external {
    require(status == Status.Taken, "NOT_ALLOW_FORCED_CLOSE");
    require(tx.accounts.signer.key == platformPubKey, "INVALID_PLATFORM");
    indemnitee = _indemnitee;
    if (indemnitee == Indemnitee.Maker) {
      isMakerRedemption = false;
      indemniteePubKey = makerPubKey;
    }
    if (indemnitee == Indemnitee.Taker) {
      isTakerRedemption = false;
      indemniteePubKey = takerPubKey;
    }
    isIndemniteeReceived = false;
    status = Status.ForceCompleted;
  }

  @mutableSigner(signer)
  function indemniteeReceiveCompensation() external {
    require(
      status == Status.ForceCompleted && isIndemniteeReceived == false,
      "NOT_ALLOW_RECEIVE_COMPENSATION"
    );
    require(tx.accounts.signer.key == indemniteePubKey, "INVALID_INDEMITEE");
    tx.accounts.dataAccount.lamports -= depositLamports;
    tx.accounts.signer.lamports += depositLamports;
    isIndemniteeReceived = true;
  }
}
