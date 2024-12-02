//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../lib/forge-std/src/Test.sol";
import "../src/game-factory.sol";
import "../src/game.sol";
import {FatToken} from "../src/fat-token.sol";
import {GameFactory} from "../src/game-factory.sol";
import {MerkleTree} from "../lib/openzeppelin-contracts/contracts/utils/structs/MerkleTree.sol";
import {RootInfo, Attack, Result} from "../src/utils/structs.sol";
import {SoapToken} from "../src/soap-token.sol";
import {Upgrades} from "../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

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
  bytes32 public merkleTreePlayerADefend = bytes32(0x1478da7d4865c2b3932949620cfe2a65cdb75df475c93ac1308b56c27e63a4ff);
  bytes32 public merkleTreePlayerAAttack = bytes32(0x491fb725fd9f59d19ddf55aa4247eb8bc7bab6f5335134d316e370182f541dd9);
  bytes32 public merkleTreePlayerBDefend = bytes32(0x1478da7d4865c2b3932949620cfe2a65cdb75df475c93ac1308b56c27e63a4ff);
  bytes32 public merkleTreePlayerBAttack = bytes32(0x491fb725fd9f59d19ddf55aa4247eb8bc7bab6f5335134d316e370182f541dd9);

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
    vm.expectEmit(false, true, true,true);
    emit GameFactory.FlightClub_GameCreated(address(0), playerA, fatToken.balanceOf(playerA));
    Game game = Game(_createGame(playerA, playerA.balance));

    //todo: test deleteTo
    assertEq(game.creator(), playerA, "game's creator is msgSender");

    vm.stopPrank();
  }

  function testJoin() public {
    //createGame
    vm.deal(playerA, 1 ether);

    vm.startPrank(playerA);
    fatToken.mint{value: playerA.balance}(playerA);
    Game game = Game(_createGame(playerA, playerA.balance));
    vm.stopPrank();

    //join
    vm.deal(playerB, 1 ether);
    vm.startPrank(playerB);

    fatToken.mint{value: playerB.balance}(playerB);
    vm.expectEmit();
    emit Game.FlightClubGame_GuestJoin(playerB);
    _join(playerB, address(game));

    vm.stopPrank();
    //todo: test deleteTo
    assertEq(playerB, game.guest(), "joiner is guest");
  }

  function testRequestAndRespondAttack_Success() public {
    //createGame
    vm.deal(playerA, 1 ether);
    vm.startPrank(playerA);
    fatToken.mint{value: playerA.balance}(playerA);
    Game game = Game(_createGame(playerA, playerA.balance));
    vm.stopPrank();

    //join
    vm.deal(playerB, 1 ether);
    vm.startPrank(playerB);
    fatToken.mint{value: playerB.balance}(playerB);
    _join(playerB, address(game));
    vm.stopPrank();

    //playerA call attackOnChain
    vm.startPrank(playerA);
    Attack memory playAAttack = Attack({
      target: 0x1,
      nonce: 0x0
    });
    bytes32[] memory proof = new bytes32[](1);
    proof[0] = bytes32(0x86718b11f5e1187ce1581907bbccb568131d598fe80ee57606046e89f66e0121);
    vm.expectEmit();
    emit Game.FlightClubGame_Attack(playerA, playAAttack.target, playAAttack.nonce, proof);
    _attack(playAAttack, proof, game);
    vm.stopPrank();

    // playerB respond attack
    vm.startPrank(playerB);
    Cell memory playerBCell = Cell({
      id: 0x1,
      status: 2,
      nonce: 0x0
    });
    bytes32[] memory playerBCellProof = new bytes32[](1);
    playerBCellProof[0] = bytes32(0x13ed295df1882ece9c4e8d5f9825eb0f67450235f915dbf1869e57190597c046);
    vm.expectEmit();
    emit Game.FlightClubGame_respondAttack(playerB,playerBCell.id,playerBCell.status,playerBCell.nonce);
    _respondAttack(playerBCell, playerBCellProof,game);

    vm.stopPrank();
  }

  function testGameWin() public {
    // playerA createGame and delegate to game contract
    vm.deal(playerA, 1 ether);
    vm.startPrank(playerA,playerA);
    fatToken.mint{value: playerA.balance}(playerA);
    Game game = Game(_createGame(playerA, playerA.balance));
    vm.stopPrank();

    // playerB join and delegate to game contract
    vm.deal(playerB, 1 ether);
    vm.startPrank(playerB,playerB);
    fatToken.mint{value: playerB.balance}(playerB);
    _join(playerB, address(game));
    vm.stopPrank();


    //==== winner playerA (attacked head of plane 3 times)
    //==== complete attack round 1 (including request and respond)
    // playerA request attack ["0x1", "0x0"]
    vm.startPrank(playerA);
    Attack memory playAAttack1 = Attack({
      target: 0x1,
      nonce: 0x0
    });
    bytes32[] memory playAAttack1Proof = new bytes32[](1);
    playAAttack1Proof[0] = bytes32(0x86718b11f5e1187ce1581907bbccb568131d598fe80ee57606046e89f66e0121);
    _attack(playAAttack1, playAAttack1Proof, game);
    vm.stopPrank();

    // playerB respond attack ["0x1", "0x2","0x0"]
    vm.startPrank(playerB);
    Cell memory playerBCell1 = Cell({
      id: 0x1,
      status: 0x2,
      nonce: 0x0
    });
    bytes32[] memory playerBCellProof1 = new bytes32[](1);
    playerBCellProof1[0] = bytes32(0x13ed295df1882ece9c4e8d5f9825eb0f67450235f915dbf1869e57190597c046);
    _respondAttack(playerBCell1,playerBCellProof1, game);
    vm.stopPrank();

    // playerB request attack target 1 ["0x1", "0x0"]
    vm.startPrank(playerB);
    Attack memory playBAttack1 = Attack({
      target: 0x1,
      nonce: 0x0
    });
    bytes32[] memory playBAttack1Proof = new bytes32[](1);
    playBAttack1Proof[0] = bytes32(0x86718b11f5e1187ce1581907bbccb568131d598fe80ee57606046e89f66e0121);
    _attack(playBAttack1, playBAttack1Proof, game);
    vm.stopPrank();

    // playerA respond attack ["0x1", "0x2","0x0"]
    vm.startPrank(playerA);
    Cell memory playerACell1 = Cell({
      id: 0x1,
      status: 0x2,
      nonce: 0x0
    });
    bytes32[] memory playerACellProof1 = new bytes32[](1);
    playerACellProof1[0] = bytes32(0x13ed295df1882ece9c4e8d5f9825eb0f67450235f915dbf1869e57190597c046);
    _respondAttack(playerACell1,playerACellProof1, game);
    vm.stopPrank();

    //==== complete attack round 2
    // playerA request attack ["0x2", "0x0"]
    vm.startPrank(playerA);
    Attack memory playAAttack2 = Attack({
      target: 0x2,
      nonce: 0x0
    });
    bytes32[] memory playAAttack2Proof = new bytes32[](2);
    playAAttack2Proof[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
    playAAttack2Proof[1] = bytes32(0x3f9553dc324cd1fd24b54243720c42e18e5c20165bc5e523e42b440a8654abd1);
    _attack(playAAttack2, playAAttack2Proof, game);
    vm.stopPrank();

    // playerB respond attack ["0x2", "0x2","0x0"]
    vm.startPrank(playerB);
    Cell memory playerBCell2 = Cell({
      id: 0x2,
      status: 0x2,
      nonce: 0x0
    });
    bytes32[] memory playerBCellProof2 = new bytes32[](2);
    playerBCellProof2[0] = bytes32(0x2ddbe54d914fe21fc7e054af975670c85b6b80f9652503ca23a624e96f433c79);
    playerBCellProof2[1] = bytes32(0xa955c8780e13d05ae4301948056ccd9ae5ca84322f5d5d44a10b11f0664758f7);
    _respondAttack(playerBCell2,playerBCellProof2, game);
    vm.stopPrank();

    // playerB request attack target 2 ["0x2", "0x0"]
    vm.startPrank(playerB);
    Attack memory playBAttack2 = Attack({
      target: 0x2,
      nonce: 0x0
    });
    bytes32[] memory playBAttack2Proof = new bytes32[](2);
    playBAttack2Proof[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
    playBAttack2Proof[1] = bytes32(0x3f9553dc324cd1fd24b54243720c42e18e5c20165bc5e523e42b440a8654abd1);
    _attack(playBAttack2, playBAttack2Proof, game);
    vm.stopPrank();

    // playerA respond attack ["0x2", "0x2","0x0"]
    vm.startPrank(playerA);
    Cell memory playerACell2 = Cell({
      id: 0x2,
      status: 0x2,
      nonce: 0x0
    });
    bytes32[] memory playerACellProof2 = new bytes32[](2);
    playerACellProof2[0] = bytes32(0x2ddbe54d914fe21fc7e054af975670c85b6b80f9652503ca23a624e96f433c79);
    playerACellProof2[1] = bytes32(0xa955c8780e13d05ae4301948056ccd9ae5ca84322f5d5d44a10b11f0664758f7);
    _respondAttack(playerACell2,playerACellProof2, game);
    vm.stopPrank();

    //==== complete attack round 3
    //==== When playerA attacked, playerA can call Game.winnerConfirmByResult() to win the game.
    // playerA request attack ["0x2", "0x0"]
    vm.startPrank(playerA);
    Attack memory playAAttack3 = Attack({
      target: 0x3,
      nonce: 0x0
    });
    bytes32[] memory playAAttack3Proof = new bytes32[](2);
    playAAttack3Proof[0] = bytes32(0x1cc5dcd5de6bb5e1f7c4a928dc89b7e9d1f623bcb525344ccd68ad5beab9bb1d);
    playAAttack3Proof[1] = bytes32(0x3f9553dc324cd1fd24b54243720c42e18e5c20165bc5e523e42b440a8654abd1);
    _attack(playAAttack3, playAAttack3Proof, game);
    vm.stopPrank();

    // playerB respond attack ["0x3", "0x2","0x0"]
    vm.startPrank(playerB);
    Cell memory playerBCell3 = Cell({
      id: 0x3,
      status: 0x2,
      nonce: 0x0
    });
    bytes32[] memory playerBCellProof3 = new bytes32[](2);
    playerBCellProof3[0] = bytes32(0x3cb7d7998d5d745cca6b9cf4672959379dbfdf42f377b3947c8e722e1c95d6c9);
    playerBCellProof3[1] = bytes32(0xa955c8780e13d05ae4301948056ccd9ae5ca84322f5d5d44a10b11f0664758f7);
  _respondAttack(playerBCell3,playerBCellProof3, game);
    vm.stopPrank();
//
//    // playerB request attack target 3 ["0x3", "0x0"]
//    vm.startPrank(playerB);
//    Attack memory playBAttack3 = Attack({
//      target: 0x3,
//      nonce: 0x0
//    });
//    bytes32[] memory playBAttack3Proof = new bytes32[](2);
//    playBAttack3Proof[0] = bytes32(0x1cc5dcd5de6bb5e1f7c4a928dc89b7e9d1f623bcb525344ccd68ad5beab9bb1d);
//    playBAttack3Proof[1] = bytes32(0x3f9553dc324cd1fd24b54243720c42e18e5c20165bc5e523e42b440a8654abd1);
//    _attack(playBAttack2, proof, game);
//    vm.stopPrank();
//
//    // playerA respond attack ["0x3", "0x2","0x0"]
//    vm.startPrank(playerA);
    Cell memory playerACell3 = Cell({
      id: 0x3,
      status: 0x2,
      nonce: 0x0
    });
    bytes32[] memory playerACellProof3 = new bytes32[](2);
    playerACellProof3[0] = bytes32(0x3cb7d7998d5d745cca6b9cf4672959379dbfdf42f377b3947c8e722e1c95d6c9);
    playerACellProof3[1] = bytes32(0xa955c8780e13d05ae4301948056ccd9ae5ca84322f5d5d44a10b11f0664758f7);
//    _respondAttack(playerACell3, game);
//    vm.stopPrank();

    //==== playerA win this game
    //==== struct the result
    // proofs
    bytes32[][3] memory playerAProofs;
    bytes32[][3] memory playerBProofs;

    playerAProofs[0] = playerACellProof1;
    playerAProofs[1] = playerACellProof2;
    playerAProofs[2] = playerACellProof3;

    playerBProofs[0] = playerBCellProof1;
    playerBProofs[1] = playerBCellProof2;
    playerBProofs[2] = playerBCellProof3;

    Result memory playerAResult = Result({
      cells: [playerACell1,playerACell2,playerACell3],
      proofs: playerAProofs
    });
    Result memory playerBResult = Result({
      cells: [playerBCell1,playerBCell2,playerBCell3],
      proofs: playerBProofs
    });
    vm.prank(playerA);
    vm.expectEmit();
    emit Game.FlightClubGame_GameEnded(playerA);
    game.winnerConfirmByResult(playerBResult,playerAResult);

  }

  function _attack(Attack memory attack, bytes32[] memory proof, Game game) internal {
    game.requestAttackOnChain(attack,proof);
  }

  function _respondAttack(Cell memory cell,bytes32[] memory proof, Game game) internal{
    game.respondAttackOnChain(cell, proof);
  }

  function _createGame(address creator, uint bet) internal returns (address){
    //generate merkleRoot
    RootInfo memory rootInfo = RootInfo({
      attackRoot: merkleTreePlayerAAttack,
      cellRoot: merkleTreePlayerADefend
    });

    return factory.createGame(fatToken.balanceOf(playerA), rootInfo);
  }

  function _join(address joiner, address gameAddress) internal {
    RootInfo memory rootInfo = RootInfo({
      attackRoot: merkleTreePlayerBAttack,
      cellRoot: merkleTreePlayerBDefend
    });

    Game game = Game(gameAddress);
    game.join(rootInfo);
  }


}
