// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract SoapToken is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {

  error SoapToken_InvalidMinter(address operator);
  /*
    Sn = n(a1+an)/2
    a1 = soapToken.INITIAL_MINT_AMOUNT();
    n = soapToken.INITIAL_MINT_AMOUNT()/soapToken.DECREMENT_PER_STEP();
    an = a1 - (n-1)*soapToken.DECREMENT_PER_STEP();
    maxSupply = n*(a1+an)/2;
    maxSupply = 5000.5 ether
  */
  uint256 public constant INITIAL_MINT_AMOUNT = 1 ether;
  uint256 public constant DECREMENT_PER_STEP = 0.0001 ether;

  uint256 public currentReward;
  address private _minterManager;
  mapping(address ca => bool) private _isMinter;

  modifier onlyMinter() {
    if (!_isMinter[msg.sender]) {
      revert SoapToken_InvalidMinter(msg.sender);
    }
    _;
  }

  modifier onlyMinterManager() {
    require(msg.sender == _minterManager, "Invalid minter manager");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

  function init(address initialOwner) public initializer {
    __ERC20_init("Soap", "SOAP");
    __Ownable_init(initialOwner);
    currentReward = INITIAL_MINT_AMOUNT;
  }

  function mint(address to) external onlyMinter {
    require(currentReward > 0, "All tokens minted");
    _mint(to, currentReward);
    currentReward -= DECREMENT_PER_STEP;
  }

  //set minterManager after factory deployed
  function setMintManager(address mintManager) public onlyOwner{
    _minterManager = mintManager;
  }


  function setMinter(address minter) public onlyMinterManager {
    _isMinter[minter] = true;
  }

  function isMintable() public view returns(bool) {
    return currentReward > 0;
  }
}
