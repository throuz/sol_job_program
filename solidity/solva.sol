import "../libraries/system_instruction.sol";

@program_id("GuvvxMUBDziMyyB2fy7XoUy7cLE5mHQiBNwPzHHHDtSg")
contract solva {
  address private platformPubKey;
  address private expertPubKey;
  address private clientPubKey;
  uint64 private caseAmountLamports;
  uint64 private expertDepositLamports;
  uint64 private clientDepositLamports;
  Status private status;

  enum Status {
    Created,
    Canceled,
    Activated,
    ForceClosed,
    Completed
  }

  @payer(expert)
  constructor(
    address _platformPubKey,
    address _clientPubKey,
    uint64 _caseAmountLamports,
    uint64 _expertDepositLamports,
    uint64 _clientDepositLamports
  ) {
    platformPubKey = _platformPubKey;
    expertPubKey = tx.accounts.expert.key;
    clientPubKey = _clientPubKey;
    caseAmountLamports = _caseAmountLamports;
    expertDepositLamports = _expertDepositLamports;
    clientDepositLamports = _clientDepositLamports;
    if (expertDepositLamports > 0) {
      SystemInstruction.transfer(
        tx.accounts.expert.key,
        tx.accounts.dataAccount.key,
        expertDepositLamports
      );
    }
    status = Status.Created;
  }

  @mutableAccount(DA)
  @mutableSigner(expert)
  function expertCancelCase() external {
    require(status == Status.Created);
    require(tx.accounts.expert.key == expertPubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.DA.lamports -= expertDepositLamports;
      tx.accounts.expert.lamports += expertDepositLamports;
    }
    status = Status.Canceled;
  }

  @mutableAccount(DA)
  @mutableSigner(client)
  function clientActivateCase(uint64 _clientDepositLamports) external {
    require(status == Status.Created);
    require(tx.accounts.client.key == clientPubKey);
    require(clientDepositLamports == _clientDepositLamports);
    if (clientDepositLamports > 0) {
      SystemInstruction.transfer(
        tx.accounts.client.key, tx.accounts.DA.key, clientDepositLamports
      );
    }
    status = Status.Activated;
  }

  @mutableAccount(DA)
  @mutableSigner(platform)
  @mutableAccount(expert)
  function platformForceCloseCaseForExpert() external {
    require(status == Status.Activated);
    require(tx.accounts.platform.key == platformPubKey);
    require(tx.accounts.expert.key == expertPubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.DA.lamports -= expertDepositLamports;
      tx.accounts.expert.lamports += expertDepositLamports;
    }
    if (clientDepositLamports > 0) {
      tx.accounts.DA.lamports -= clientDepositLamports;
      tx.accounts.expert.lamports += clientDepositLamports;
    }
    status = Status.ForceClosed;
  }

  @mutableAccount(DA)
  @mutableSigner(platform)
  @mutableAccount(client)
  function platformForceCloseCaseForClient() external {
    require(status == Status.Activated);
    require(tx.accounts.platform.key == platformPubKey);
    require(tx.accounts.client.key == clientPubKey);
    if (expertDepositLamports > 0) {
      tx.accounts.DA.lamports -= expertDepositLamports;
      tx.accounts.client.lamports += expertDepositLamports;
    }
    if (clientDepositLamports > 0) {
      tx.accounts.DA.lamports -= clientDepositLamports;
      tx.accounts.client.lamports += clientDepositLamports;
    }
    status = Status.ForceClosed;
  }

  @mutableAccount(DA)
  @mutableAccount(platform)
  @mutableAccount(expert)
  @mutableSigner(client)
  function clientCompleteCase() external {
    require(status == Status.Activated);
    require(tx.accounts.platform.key == platformPubKey);
    require(tx.accounts.expert.key == expertPubKey);
    require(tx.accounts.client.key == clientPubKey);
    uint64 platformIncome = caseAmountLamports * 1 / 100;
    uint64 expertIncome = caseAmountLamports * 99 / 100;
    SystemInstruction.transfer(
      tx.accounts.client.key, tx.accounts.platform.key, platformIncome
    );
    SystemInstruction.transfer(
      tx.accounts.client.key, tx.accounts.expert.key, expertIncome
    );
    if (expertDepositLamports > 0) {
      tx.accounts.DA.lamports -= expertDepositLamports;
      tx.accounts.expert.lamports += expertDepositLamports;
    }
    if (clientDepositLamports > 0) {
      tx.accounts.DA.lamports -= clientDepositLamports;
      tx.accounts.client.lamports += clientDepositLamports;
    }
    status = Status.Completed;
  }
}
