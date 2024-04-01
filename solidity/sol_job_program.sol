import "../libraries/system_instruction.sol";

@program_id("D5Y1bmRzxQK8RSTGbxMBHkfa2DEmxZU2qcoiEX1PABeJ")
contract sol_job_program {
  address private platformPubKey;
  address private makerPubKey;
  address private takerPubKey;
  uint64 private budgetLamports;
  uint64 private securityDepositLamports;

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
    uint64 _budgetLamports,
    uint64 _securityDepositLamports
  ) {
    platformPubKey = _platformPubKey;
    makerPubKey = tx.accounts.payer.key;
    budgetLamports = _budgetLamports;
    securityDepositLamports = _securityDepositLamports;
    SystemInstruction.transfer(
      tx.accounts.payer.key,
      tx.accounts.dataAccount.key,
      securityDepositLamports
    );
    status = Status.Pending;
  }

  @mutableSigner(signer)
  function takeCase() external {
    require(status == Status.Pending, "NOT_ALLOW_TAKE");
    takerPubKey = tx.accounts.signer.key;
    SystemInstruction.transfer(
      takerPubKey, tx.accounts.dataAccount.key, securityDepositLamports
    );
    status = Status.Taken;
  }

  @mutableSigner(signer)
  function confirmCaseComplete() external {
    require(status == Status.Taken, "NOT_ALLOW_COMPLETE");
    require(tx.accounts.signer.key == makerPubKey, "INVALID_MAKER");
    address dataAccountPubKey = tx.accounts.dataAccount.key;
    SystemInstruction.transfer(
      makerPubKey, dataAccountPubKey, budgetLamports - securityDepositLamports
    );
    status = Status.Unpaid;
  }

  @mutableSigner(signer)
  function payToTaker() external {
    require(status == Status.Unpaid, "NOT_ALLOW_PAY_TO");
    require(tx.accounts.signer.key == takerPubKey, "INVALID_TAKER");
    tx.accounts.dataAccount.lamports -= budgetLamports;
    tx.accounts.signer.lamports += budgetLamports;
    status = Status.Paid;
  }

  @mutableSigner(signer)
  function closeCase() external {
    require(status == Status.Paid, "NOT_ALLOW_CLOSE");
    require(tx.accounts.signer.key == platformPubKey, "INVALID_PLATFORM");
    tx.accounts.dataAccount.lamports -= securityDepositLamports * 2 / 100;
    tx.accounts.signer.lamports += securityDepositLamports * 2 / 100;
    status = Status.Closed;
  }
}
