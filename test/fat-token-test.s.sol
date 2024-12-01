//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../lib/forge-std/src/Test.sol";
import "../src/fat-token.sol";
import "../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

contract FatTokenTest is Test {

  //proxy
  FatToken public fatToken;
  address payable public fatTokenAddress;

  address public admin = vm.randomAddress();
  address public userA = vm.randomAddress();
  address public userB = vm.randomAddress();

  function setUp() public {
    vm.startPrank(admin);

    bytes memory initData = abi.encodeWithSelector(FatToken.initialize.selector, admin);
    fatTokenAddress = payable (Upgrades.deployUUPSProxy("fat-token.sol:FatToken", initData));
    fatToken = FatToken(fatTokenAddress);

    vm.stopPrank();
  }

  function _adminMint() internal {
    deal(admin,1 ether);
    vm.prank(admin);
    fatTokenAddress.call{value: 1 ether}("");
  }

  function testMint() public {
    _adminMint();
    assertEq(fatToken.balanceOf(admin), fatToken.FATS_PER_ETH()* 1 ether);
  }

  function testBurn() public {
    _adminMint();
    uint256 burnAmount = fatToken.balanceOf(admin);
    vm.prank(admin);
    fatToken.burn(payable(userA), burnAmount);
    assertEq(userA.balance, burnAmount / fatToken.FATS_PER_ETH());
  }

  function _txoriginDelegateToUserA() internal {
    deal(fatTokenAddress, tx.origin, 3 ether);
    vm.prank(tx.origin);
    fatToken.delegateTo(userA);
    vm.prank(userA);
    fatToken.transferFrom(tx.origin,userA, 1 ether);
  }

  function testDelegateTo() public {
    _txoriginDelegateToUserA();
    assertEq(fatToken.balanceOf(userA), 1 ether);
    // only delegator: userA can transfer token.
    vm.expectRevert();
    vm.prank(tx.origin);
    fatToken.transfer(userA, 1 ether);
  }

  function testUnDelegateTo() public {
    _txoriginDelegateToUserA();

    vm.prank(userA);
    fatToken.undelegate(tx.origin);

    vm.prank(tx.origin);
    fatToken.transfer(userA, 1 ether);

    // only delegator: userA can transfer token.
    vm.expectRevert();
    vm.prank(userA);
    fatToken.transferFrom(tx.origin, userA,1 ether);
  }
}
