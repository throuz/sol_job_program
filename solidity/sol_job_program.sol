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
    Accepted,
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
    status = Status.Accepted;
  }

  @mutableSigner(signer)
  function closeCase() external {
    require(status == Status.Accepted, "NOT_ALLOW_CLOSE");
    require(tx.accounts.signer.key == makerPubKey, "INVALID_MAKER");
    address dataAccountPubKey = tx.accounts.dataAccount.key;
    SystemInstruction.transfer(
      dataAccountPubKey, platformPubKey, securityDepositLamports * 2 / 100
    );
    SystemInstruction.transfer(
      dataAccountPubKey, makerPubKey, securityDepositLamports * 99 / 100
    );
    SystemInstruction.transfer(
      dataAccountPubKey, takerPubKey, securityDepositLamports * 99 / 100
    );
    SystemInstruction.transfer(makerPubKey, takerPubKey, budgetLamports);
    status = Status.Closed;
  }

  @mutableSigner(signer)
  @mutableAccount(winnerAccount)
  function closeCaseByPlatform() external {
    require(status == Status.Accepted, "NOT_ALLOW_CLOSE");
    require(tx.accounts.signer.key == platformPubKey, "INVALID_PLATFORM");
    address dataAccountPubKey = tx.accounts.dataAccount.key;
    SystemInstruction.transfer(
      dataAccountPubKey, platformPubKey, securityDepositLamports * 2 / 100
    );
    SystemInstruction.transfer(
      dataAccountPubKey,
      tx.accounts.winnerAccount.key,
      securityDepositLamports * 198 / 100
    );
    status = Status.Closed;
  }
}
