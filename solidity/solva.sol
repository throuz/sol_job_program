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

  @mutableAccount(platform)
  @payer(expert)
  constructor(
    address _clientPubKey,
    uint64 _caseAmountLamports,
    uint64 _expertDepositLamports,
    uint64 _clientDepositLamports
  ) {
    platformPubKey = tx.accounts.platform.key;
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
    uint64 platformFee = caseAmountLamports * 1 / 100;
    SystemInstruction.transfer(
      tx.accounts.expert.key, tx.accounts.platform.key, platformFee
    );
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
  @mutableAccount(platform)
  @mutableSigner(client)
  function clientActivateCase(uint64 _clientDepositLamports) external {
    require(status == Status.Created);
    require(tx.accounts.platform.key == platformPubKey);
    require(tx.accounts.client.key == clientPubKey);
    require(clientDepositLamports == _clientDepositLamports);
    if (clientDepositLamports > 0) {
      SystemInstruction.transfer(
        tx.accounts.client.key, tx.accounts.DA.key, clientDepositLamports
      );
    }
    uint64 platformFee = caseAmountLamports * 1 / 100;
    SystemInstruction.transfer(
      tx.accounts.client.key, tx.accounts.platform.key, platformFee
    );
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
    SystemInstruction.transfer(
      tx.accounts.client.key, tx.accounts.expert.key, caseAmountLamports
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
