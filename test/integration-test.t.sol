//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../lib/forge-std/src/Test.sol";
import {FatToken} from "../src/fat-token.sol";
import {SoapToken} from "../src/soap-token.sol";
import {GameFactory} from "../src/game-factory.sol";
import {Upgrades} from "../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import {RootInfo} from "../src/utils/structs.sol";
import {MerkleTree} from "../lib/openzeppelin-contracts/contracts/utils/structs/MerkleTree.sol";
import "../src/game.sol";

contract IntegrationTest is Test {

  FatToken public fatToken;
  address payable public fatTokenAddress;

  SoapToken public soapToken;
  address public soapTokenAddress;

  GameFactory public factory;
  address public factoryAddress;

  address public admin = vm.randomAddress();
  //creator
  address public playerA = vm.randomAddress();
  address public playerB = vm.randomAddress();

  //generate offline https://github.com/OpenZeppelin/merkle-tree
  bytes32 public merkleTreePlayerADefend = bytes32(vm.randomUint());
  bytes32 public merkleTreePlayerAAttack = bytes32(vm.randomUint());
  bytes32 public merkleTreePlayerBDefend = bytes32(vm.randomUint());
  bytes32 public merkleTreePlayerBAttack = bytes32(vm.randomUint());
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
    fatTokenAddress = payable(Upgrades.deployUUPSProxy("fat-token.sol:FatToken", initData));
    fatToken = FatToken(fatTokenAddress);

    //soapToken
    initData = abi.encodeWithSelector(SoapToken.init.selector, admin);
    soapTokenAddress = Upgrades.deployUUPSProxy("soap-token.sol:SoapToken", initData);
    soapToken = SoapToken(soapTokenAddress);

    //factory
    initData = abi.encodeWithSelector(GameFactory.initialize.selector, admin, fatTokenAddress, soapTokenAddress);
    factoryAddress = Upgrades.deployUUPSProxy("game-factory.sol:GameFactory", initData);
    factory = GameFactory(factoryAddress);
    Game game = new Game();
    factory.setGameImplementation(address(game));

    //config soapToken
    soapToken.setMintManager(factoryAddress);

    vm.stopPrank();
  }

  function testCreateGame() public {
    vm.deal(playerA, 1 ether);

    vm.startPrank(playerA);

    fatToken.mint{value: playerA.balance}(playerA);
    Game game = Game(createGame(playerA, playerA.balance));

    //todo: deleteTo
    assertEq(game.creator(), playerA, "game's creator is msgSender");


    vm.stopPrank();
  }

  function testJoin() public {
    //createGame
    vm.deal(playerA, 1 ether);

    vm.startPrank(playerA);
    fatToken.mint{value: playerA.balance}(playerA);
    Game game = Game(createGame(playerA, playerA.balance));
    vm.stopPrank();

    //join
    vm.deal(playerB, 1 ether);

    vm.startPrank(playerB);
    fatToken.mint{value: playerB.balance}(playerB);
    join(playerB,address (game));
    vm.stopPrank();
    //todo: deleteTo
    assertEq(playerB, game.guest(),"joiner is guest");
  }




  function createGame(address creator, uint bet) public returns(address){
    //generate merkleRoot
    RootInfo memory rootInfo = RootInfo({
      attackRoot: merkleTreePlayerAAttack,
      cellRoot: merkleTreePlayerADefend
    });

    return factory.createGame(fatToken.balanceOf(playerA), rootInfo);
  }

  function join(address joiner,address gameAddress) public {
    RootInfo memory rootInfo = RootInfo({
      attackRoot: merkleTreePlayerBAttack,
      cellRoot: merkleTreePlayerBDefend
    });

    Game game = Game(gameAddress);
    game.join(rootInfo);
  }


}
