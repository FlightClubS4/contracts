// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// TODO: 改为可升级 CY
contract SoapToken is ERC20, Ownable {

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

  uint256 public currentReward = INITIAL_MINT_AMOUNT;

  constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) Ownable(msg.sender){}

  function mint(address to) external onlyOwner {
    require(currentReward > 0, "All tokens minted");

    _mint(to, currentReward);
    currentReward -= DECREMENT_PER_STEP;
  }

}
