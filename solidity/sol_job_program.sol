// @program_id("7knLbMVcZSW8Ha52YS7kNuhQXF13iW4t1WB125tx6qob")
// contract sol_job_program {
//   bool private value = true;

//   @payer(payer)
//   constructor() {
//     print("Hello, World!");
//   }

//   /// A message that can be called on instantiated contracts.
//   /// This one flips the value of the stored `bool` from `true`
//   /// to `false` and vice versa.
//   function flip() public {
//     value = !value;
//   }

//   /// Simply returns the current value of our `bool`.
//   function get() public view returns (bool) {
//     return value;
//   }
// }

@program_id("9cvE2LqwkzQX2RXFBPH4XrHfs4VcdHRbCFDSWDFTwrw1")
contract sol_job_program {
  address public owner;
  address public thirdPartyPlatform;
  address public leader;
  uint256 public owerUsdtAmount;
  uint256 public leaderUsdtAmount;
  bool public contractInitiated;
  bool public ownerAgreed;
  bool public leaderSigned;
  bool public collateralTransferred;
  string public requirement;
  uint256 public expirationTime;

  event ContractInitiated(
    address indexed owner,
    address indexed thirdPartyPlatform,
    string indexed requirementAndAmount
  );

  @signer(authorityAccount)
  @payer(payer)
  constructor(address new_authority) {
    thirdPartyPlatform = new_authority;

    contractInitiated = false;
    ownerAgreed = false;
    leaderSigned = false;
    collateralTransferred = false;
  }


  function initiateContract(
    address _owner,
    string memory _requirement,
    uint256 _owerUsdtAmount,
    uint256 _expirationTime
  ) external payable returns (string memory) {
    require(!contractInitiated, "Contract has already been initiated");
    // initiate contract var
    requirement = _requirement;
    expirationTime = _expirationTime;
    owerUsdtAmount = _owerUsdtAmount;

    owner = _owner;

    string memory descriptionOfrequirment =
      string(abi.encodePacked("reauirment is : ", requirement));
    string memory owerUsdtAmountStr =
      string(abi.encodePacked("usdt amount is : ", owerUsdtAmount));
    string memory requirementAndAmount =
      string(abi.encodePacked(descriptionOfrequirment, owerUsdtAmountStr));

    emit ContractInitiated(owner, thirdPartyPlatform, requirementAndAmount); // 發送通知給業主以及第三方平台

    contractInitiated = true;
    return "initiate contract";
  }
}
