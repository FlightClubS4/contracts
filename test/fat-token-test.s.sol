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

  function testMint() public {

  }

  function testBurn() public {

  }

  function testDelegateTo() public {

  }

  function testUnDelegateTo() public {

  }
}
