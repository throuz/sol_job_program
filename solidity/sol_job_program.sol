import "../libraries/system_instruction.sol";

@program_id("D5Y1bmRzxQK8RSTGbxMBHkfa2DEmxZU2qcoiEX1PABeJ")
contract sol_job_program {
  address private platformPubKey;
  address private makerPubKey;
  address private takerPubKey;
  uint64 private totalLamports;
  uint64 private depositLamports;

  enum Status {
    Pending,
    Taken,
    Unpaid,
    Paid,
    Closed
  }

  Status private status;

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
    status = Status.Unpaid;
  }

  @mutableSigner(signer)
  function takerGetIncome() external {
    require(status == Status.Unpaid, "NOT_ALLOW_GET_INCOME");
    require(tx.accounts.signer.key == takerPubKey, "INVALID_TAKER");
    tx.accounts.dataAccount.lamports -= totalLamports * 99 / 100;
    tx.accounts.signer.lamports += totalLamports * 99 / 100;
    status = Status.Paid;
  }

  @mutableSigner(signer)
  function makerRedemptionDeposit() external {
    require(status == Status.Paid, "NOT_ALLOW_REDEMPTION_DEPOSIT");
    require(tx.accounts.signer.key == makerPubKey, "INVALID_MAKER");
    tx.accounts.dataAccount.lamports -= depositLamports;
    tx.accounts.signer.lamports += depositLamports;
  }

  @mutableSigner(signer)
  function takerRedemptionDeposit() external {
    require(status == Status.Paid, "NOT_ALLOW_REDEMPTION_DEPOSIT");
    require(tx.accounts.signer.key == takerPubKey, "INVALID_TAKER");
    tx.accounts.dataAccount.lamports -= depositLamports;
    tx.accounts.signer.lamports += depositLamports;
  }

  @mutableSigner(signer)
  function platformCloseCase() external {
    require(status == Status.Paid, "NOT_ALLOW_CLOSE");
    require(tx.accounts.signer.key == platformPubKey, "INVALID_PLATFORM");
    tx.accounts.dataAccount.lamports -= totalLamports * 1 / 100;
    tx.accounts.signer.lamports += totalLamports * 1 / 100;
    status = Status.Closed;
  }
}
