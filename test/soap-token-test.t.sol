//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../lib/forge-std/src/Test.sol";
import "../src/soap-token.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract SoapTokenTest is Test {

  SoapToken public soapToken;
  address public soapTokenAddress;

  address public owner = vm.randomAddress();
  address public userA = vm.randomAddress();
  address public userB = vm.randomAddress();

  /*
  owner mint token to userA
  owner mint token to userA and userB till maxSupply
  */


  function setUp() public {
    vm.startPrank(owner);

    soapToken = new SoapToken("SOAP", "SOAP");
    soapTokenAddress = address(soapToken);

    vm.stopPrank();
  }

  function testMint() public {
    vm.startPrank(owner);

    soapToken.mint(userA);
    assertEq(soapToken.balanceOf(userA), soapToken.INITIAL_MINT_AMOUNT(), "first user should receive INITIAL_MINT_AMOUNT");

    vm.stopPrank();
  }

  function testMintTillMaxSupply() public {
    vm.startPrank(owner);
    for (uint i = 1; i <= (soapToken.INITIAL_MINT_AMOUNT()/soapToken.DECREMENT_PER_STEP()); i++) {
      if (i % 2 == 0) {
        soapToken.mint(userA);
      } else {
        soapToken.mint(userB);
      }
    }
    //Sn = n(a1+an)/2
    uint a1 = soapToken.INITIAL_MINT_AMOUNT();
    uint n = soapToken.INITIAL_MINT_AMOUNT()/soapToken.DECREMENT_PER_STEP();
    uint an = a1 - (n-1)*soapToken.DECREMENT_PER_STEP();
    uint maxSupply = n*(a1+an)/2;
    console.log("maxSupply:",maxSupply);
    assertEq(soapToken.balanceOf(userA)+soapToken.balanceOf(userB),maxSupply ,"uesrA and userB get all token");
    vm.stopPrank();
  }

  function testOverMint() public {
    vm.startPrank(owner);
    for (uint i = 1; i <= (soapToken.INITIAL_MINT_AMOUNT()/soapToken.DECREMENT_PER_STEP()); i++) {
        soapToken.mint(userA);
    }

    vm.expectRevert("All tokens minted");
    soapToken.mint(userA);

    vm.stopPrank();
  }

  function testNotOwnerMint() public {
    vm.startPrank(userA);

    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, userA));
    soapToken.mint(userA);

    vm.stopPrank();
  }
}
