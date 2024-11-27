// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SoapToken is ERC20, Ownable {

  uint256 public totalMinted;
  uint256 public currentMintIndex;

  uint256 public constant MAX_SUPPLY = 100 ether;
  uint256 public constant TOTAL_MINTS_TIMES = 10000;
  uint256 public constant INITIAL_MINT_AMOUNT = 2 * MAX_SUPPLY / TOTAL_MINTS_TIMES + 1;
  uint256 public constant DECREMENT_PER_STEP = (INITIAL_MINT_AMOUNT - MAX_SUPPLY / TOTAL_MINTS_TIMES) * 2 / TOTAL_MINTS_TIMES + 1;


  constructor() ERC20("Soap", "Soap") Ownable(msg.sender){}

  function mint(address to) external onlyOwner {
    require(currentMintIndex < TOTAL_MINTS_TIMES, "All tokens minted");

    uint256 mintAmount = INITIAL_MINT_AMOUNT - (currentMintIndex * DECREMENT_PER_STEP);
    require(totalMinted + mintAmount <= MAX_SUPPLY, "Exceeds max supply");

    _mint(to, mintAmount);
    totalMinted += mintAmount;
    currentMintIndex++;
  }

}
