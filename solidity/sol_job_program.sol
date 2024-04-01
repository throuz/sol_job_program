import "../libraries/system_instruction.sol";

@program_id("D5Y1bmRzxQK8RSTGbxMBHkfa2DEmxZU2qcoiEX1PABeJ")
contract sol_job_program {
  uint64 private budgetLamports;
  uint64 private securityDepositLamports;

  @payer(payer)
  @seed("case")
  constructor(
   @seed bytes makerSeed,
   @bump bytes1 bump,
    uint64 _budgetLamports,
    uint64 _securityDepositLamports
  ) {
    (address pda, bytes1 _bump) = try_find_program_address(['case',makerSeed], address(this));
    require(bump == _bump, "INVALID_BUMP");
    budgetLamports = _budgetLamports;
    securityDepositLamports = _securityDepositLamports;
    SystemInstruction.transfer(
      tx.accounts.payer.key, pda, securityDepositLamports
    );
  }

  @mutableAccount(takerAccount)
  function takeCase() external {
    SystemInstruction.transfer(
      tx.accounts.takerAccount.key,
      tx.accounts.dataAccount.key,
      securityDepositLamports
    );
  }

  @mutableAccount(platformAccount)
  @mutableAccount(makerAccount)
  @mutableAccount(takerAccount)
  function closeCase() external {
    tx.accounts.dataAccount.lamports -= securityDepositLamports * 2;
    tx.accounts.platformAccount.lamports += securityDepositLamports * 2 / 100;
    tx.accounts.makerAccount.lamports += securityDepositLamports * 99 / 100;
    tx.accounts.takerAccount.lamports += securityDepositLamports * 99 / 100;
    SystemInstruction.transfer(
      tx.accounts.makerAccount.key, tx.accounts.takerAccount.key, budgetLamports
    );
  }

  @mutableAccount(platformAccount)
  @mutableAccount(winnerAccount)
  function closeCaseByPlatform() external {
    tx.accounts.dataAccount.lamports -= securityDepositLamports * 2;
    tx.accounts.platformAccount.lamports += securityDepositLamports * 2 / 100;
    tx.accounts.winnerAccount.lamports += securityDepositLamports * 198 / 100;
  }
}
