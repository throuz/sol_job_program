import "../libraries/system_instruction.sol";

@program_id("D5Y1bmRzxQK8RSTGbxMBHkfa2DEmxZU2qcoiEX1PABeJ")
contract sol_job_program {
  address private platformPubKey;
  address private makerPubKey;
  address private takerPubKey;
  uint64 private budgetLamports;
  uint64 private securityDepositLamports;

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
  }

  @mutableSigner(signer)
  function takeCase() external {
    takerPubKey = tx.accounts.signer.key;
    SystemInstruction.transfer(
      takerPubKey, tx.accounts.dataAccount.key, securityDepositLamports
    );
  }

  @mutableSigner(signer)
  function closeCase() external {
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
  }

  @mutableSigner(signer)
  @mutableAccount(winnerAccount)
  function closeCaseByPlatform() external {
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
  }
}
