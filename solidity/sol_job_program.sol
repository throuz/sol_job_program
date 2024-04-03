import "../libraries/system_instruction.sol";

@program_id("D5Y1bmRzxQK8RSTGbxMBHkfa2DEmxZU2qcoiEX1PABeJ")
contract sol_job_program {
  address private platformPubKey;
  address private expertPubKey;
  address private clientPubKey;
  uint64 private caseAmountLamports;
  uint64 private expertDepositLamports;
  uint64 private clientDepositLamports;
  uint64 private expirationTimestamp;
  bool private isExpertGetIncome;
  bool private isExpertRedeem;
  bool private isClientRedeem;
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
    Expired,
    ForceClosed,
    Compensated,
    Completed,
    Closed
  }

  @payer(payer)
  constructor(
    address _platformPubKey,
    uint64 _caseAmountLamports,
    uint64 _expertDepositLamports,
    uint64 _clientDepositLamports,
    uint64 _expirationTimestamp
  ) {
    platformPubKey = _platformPubKey;
    expertPubKey = tx.accounts.payer.key;
    caseAmountLamports = _caseAmountLamports;
    expertDepositLamports = _expertDepositLamports;
    clientDepositLamports = _clientDepositLamports;
    expirationTimestamp = _expirationTimestamp;
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
  function expertExpireCase() external {
    require(status == Status.Active);
    require(block.timestamp > expirationTimestamp);
    require(tx.accounts.signer.key == expertPubKey);
    tx.accounts.dataAccount.lamports -= expertDepositLamports;
    tx.accounts.signer.lamports += expertDepositLamports;
    tx.accounts.dataAccount.lamports -= clientDepositLamports;
    tx.accounts.signer.lamports += clientDepositLamports;
    status = Status.Expired;
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
  function expertCompensate() external {
    require(status == Status.ForceClosed);
    require(tx.accounts.signer.key == indemniteePubKey);
    tx.accounts.dataAccount.lamports -= expertDepositLamports;
    tx.accounts.signer.lamports += expertDepositLamports;
    tx.accounts.dataAccount.lamports -= clientDepositLamports;
    tx.accounts.signer.lamports += clientDepositLamports;
    status = Status.Compensated;
  }

  @mutableSigner(signer)
  function clientCompensate() external {
    require(status == Status.ForceClosed);
    require(tx.accounts.signer.key == indemniteePubKey);
    tx.accounts.dataAccount.lamports -= clientDepositLamports;
    tx.accounts.signer.lamports += clientDepositLamports;
    tx.accounts.dataAccount.lamports -= expertDepositLamports;
    tx.accounts.signer.lamports += expertDepositLamports;
    status = Status.Compensated;
  }

  @mutableSigner(signer)
  function clientCompleteCase() external {
    require(status == Status.Active);
    require(tx.accounts.signer.key == clientPubKey);
    SystemInstruction.transfer(
      tx.accounts.signer.key, tx.accounts.dataAccount.key, caseAmountLamports
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
    require(status == Status.Completed);
    require(isExpertGetIncome == false);
    require(tx.accounts.signer.key == expertPubKey);
    tx.accounts.dataAccount.lamports -= caseAmountLamports * 99 / 100;
    tx.accounts.signer.lamports += caseAmountLamports * 99 / 100;
    isExpertGetIncome = true;
  }

  @mutableSigner(signer)
  function expertRedeemDeposit() external {
    require(status == Status.Completed);
    require(isExpertRedeem == false);
    require(tx.accounts.signer.key == expertPubKey);
    tx.accounts.dataAccount.lamports -= expertDepositLamports;
    tx.accounts.signer.lamports += expertDepositLamports;
    isExpertRedeem = true;
  }

  @mutableSigner(signer)
  function clientRedeemDeposit() external {
    require(status == Status.Completed);
    require(isClientRedeem == false);
    require(tx.accounts.signer.key == clientPubKey);
    tx.accounts.dataAccount.lamports -= clientDepositLamports;
    tx.accounts.signer.lamports += clientDepositLamports;
    isClientRedeem = true;
  }

  @mutableSigner(signer)
  function platformCloseCase() external {
    require(status == Status.Completed);
    require(isExpertGetIncome);
    require(isExpertRedeem);
    require(isClientRedeem);
    require(tx.accounts.signer.key == platformPubKey);
    tx.accounts.dataAccount.lamports -= caseAmountLamports * 1 / 100;
    tx.accounts.signer.lamports += caseAmountLamports * 1 / 100;
    status = Status.Closed;
  }
}
