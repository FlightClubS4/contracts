//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../lib/forge-std/src/Test.sol";
import {FatToken} from "../src/fat-token.sol";
import {SoapToken} from "../src/soap-token.sol";
import {GameFactory} from "../src/game-factory.sol";
import {Upgrades} from "../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import {RootInfo} from "../src/utils/structs.sol";
import {MerkleTree} from "../lib/openzeppelin-contracts/contracts/utils/structs/MerkleTree.sol";

contract IntegrationTest is Test {

  FatToken public fatToken;
  address public fatTokenAddress;

  SoapToken public soapToken;
  address public soapTokenAddress;

  GameFactory public factory;
  address public factoryAddress;

  address public admin = vm.randomAddress();
  address public playerA = vm.randomAddress();
  address public playerB = vm.randomAddress();

//  using MerkleTree for MerkleTree.Bytes32PushTree;

//  MerkleTree.Bytes32PushTree public tree;
//  bytes32 public root;
//  bytes32 public zero = 0x0;  // 空叶子值，通常可以选择一个不会出现在树中的值

  /*
  1. depoly fat soap factory
  2. playerA (1 eth) playerB (1eth)
  3. A createGame
  4. B join
  5. A win
  6. check  A win -> playerA(2eth) playerB(0eth 1 ether soapToken)
  */

  function setUp() public {
    vm.startPrank(admin);

    //fatToken
    bytes memory initData = abi.encodeWithSelector(FatToken.initialize.selector, admin);
    fatTokenAddress = Upgrades.deployUUPSProxy("fat-token.sol:FatToken", initData);
    fatToken = FatToken(fatTokenAddress);

    //soapToken
    initData = abi.encodeWithSelector(SoapToken.init.selector, "SoapToken", "SOAP");
    soapTokenAddress = Upgrades.deployUUPSProxy("soap-token.sol:SoapToken", initData);
    soapToken = SoapToken(soapTokenAddress);

    //factory
    initData = abi.encodeWithSelector(GameFactory.initialize.selector, admin, fatTokenAddress);
    factoryAddress = Upgrades.deployUUPSProxy("game-factory.sol:GameFactory", initData);
    factory = GameFactory(factoryAddress);
    Game game = new Game();
    factory.setGameImplementation(address(game));
    vm.stopPrank();
  }

  function gameCompleteTest() public {

//
//    vm.deal(playerA, 1 ether);
//    vm.deal(playerB, 1 ether);
//
//    vm.startPrank(playerA);
//    fatToken.mint{value: playerA.balance}(playerA);
//
//    //generate merkleRoot
//    // 设置树的深度为 2（可以容纳 3 个叶子节点）
//    root = tree.setup(2, zero, Hashes.commutativeKeccak256);
//    // 插入叶子节点 0、1、2
//    (uint256 index0, bytes32 newRoot0) = tree.push(bytes32(uint256(0)));  // 节点 0
//    (uint256 index1, bytes32 newRoot1) = tree.push(bytes32(uint256(1)));  // 节点 1
//    (uint256 index2, bytes32 newRoot2) = tree.push(bytes32(uint256(2)));  // 节点 2
//    // 更新树的根
//    root = newRoot2;
//
//    RootInfo rootInfoA = RootInfo({
//      attackRoot: vm.randomUint(),
//      cellRoot: vm.randomUint()
//    });
//    factory.createGame(fatToken.balanceOf(playerA),rootInfo);
//    vm.stopPrank();
//
//    vm.startPrank(playerB);
//    fatToken.mint{value: playerB.balance}(playerB);
//    vm.stopPrank();


  }


}
