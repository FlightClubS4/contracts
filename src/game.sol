// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { FatToken } from "./fat-token.sol";
import { RootInfo, Attack, Cell, GameInitializeInfo, RaiseProposal, RaiseProof, Result } from "./utils/structs.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { SoapToken } from "./soap-token.sol";

contract Game is Initializable {
  /******************** errors ****************/
  error FlightClubGame_OnlyPlayerCanOperate(address operator, address creator, address guest);
  error FlightClubGame_GuestAlreadyExists(address guest);
  error FlightClubGame_InvalidGuest(address operator);
  error FlightClubGame_InvalidTargetCell(uint8 cellID, uint8 status);
  error FlightClubGame_InvalidRaiseProof(RaiseProof);
  error FlightClubGame_GameAlreadyEnded();
  error FlightClubGame_FatTokenBalanceIsNotEnough(address player);
  error FlightClubGame_TooLateToConfirmRaise(uint256 deadline);
  error FlightClubGame_InvalidAttackOnChain(Attack);
  /********************************************/

  /******************* events *****************/
  event FlightClubGame_GuestJoin(address guest);
  event FlightClubGame_Raise(address raiser, uint256 cellID, uint256 bet);
  event FlightClubGame_ConfirmRaise(address confirmer, uint256 cellID, uint256 bet);
  event FlightClubGame_GameEnded(address winner);
  event FlightClubGame_Attack(address attacker, uint8 target,uint248 nonce, bytes32[] proof);
  event FlightClubGame_respondAttack(address attackee, uint8 id, uint8 status,uint240 nonce);
  /********************************************/

  /******************* state *******************/
  uint256 public bet;
  address public creator;
  address public guest;
  address private _fatTokenAddr;
  address private _soapTokenAddr;
  bool private _ended;
  mapping(address player => RootInfo r) private _roots;
  mapping(address attacker => mapping(uint256 cellID => RaiseProposal)) private _raiseProposals;
  mapping(address attacker => mapping(uint256 cellID => uint256 deadline)) private _onchainRounds;
  /********************************************/

  /******************** modifier **************/
  modifier onlyPlayer() {
    if (msg.sender != creator && msg.sender != guest) {
      revert FlightClubGame_OnlyPlayerCanOperate(msg.sender, creator, guest);
    }
    _;
  }

  modifier whenNotEnded() {
    if (_ended) {
      revert FlightClubGame_GameAlreadyEnded();
    }
    _;
  }
  /********************************************/

  function _enemy() private view returns(address) {
    return msg.sender == creator ? guest : creator;
  }

  function initialize(GameInitializeInfo calldata info) initializer public {
    creator = info.creator;
    bet = info.bet;
    _fatTokenAddr = info.fatTokenAddr;
    _soapTokenAddr = info.soapTokenAddr;
    _roots[creator] = info.creatorRoot;
    FatToken fatToken = FatToken(payable(_fatTokenAddr));
    fatToken.delegateTo(address(this));
  }

  function _checkNewGuest(address newGuest) private view {
    if (guest != address(0)) {
      revert FlightClubGame_GuestAlreadyExists(guest);
    }
    if (newGuest == creator) {
      revert FlightClubGame_InvalidGuest(creator);
    }
    FatToken fatToken = FatToken(payable(_fatTokenAddr));
    uint256 balance = fatToken.balanceOf(newGuest);
    if (balance < bet) {
      revert FlightClubGame_FatTokenBalanceIsNotEnough(newGuest);
    }
  }

  // 玩家加入游戏，成为guest
  function join(RootInfo calldata root) public {
    _checkNewGuest(msg.sender);
    FatToken fatToken = FatToken(payable(_fatTokenAddr));
    guest = msg.sender;
    _roots[msg.sender] = root;
    fatToken.delegateTo(address(this));
    emit FlightClubGame_GuestJoin(msg.sender);
  }

  function verifyAttack(address attacker, Attack calldata attack, bytes32[] calldata proof) public view returns(bool) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(attack.target, attack.nonce))));
    bytes32 root = _roots[attacker].attackRoot;
    return MerkleProof.verify(proof, root, leaf);
  }

  function verifyCell(address defender, Cell calldata cell, bytes32[] calldata proof) public view returns(bool) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(cell.id, cell.status, cell.nonce))));
    bytes32 root = _roots[defender].cellRoot;
    return MerkleProof.verify(proof, root, leaf);
  }

  function requestAttackOnChain(Attack calldata attack, bytes32[] calldata proof) public onlyPlayer {
    // attaker
    require(verifyAttack(msg.sender, attack, proof), "not a valid attack");
    _onchainRounds[msg.sender][attack.target] = block.timestamp + 60 seconds;
    emit FlightClubGame_Attack(msg.sender, attack.target,attack.nonce, proof);
  }

  function respondAttackOnChain(Cell calldata cell, bytes32[] calldata proof) public onlyPlayer {
    // attakee
    require(verifyCell(msg.sender, cell, proof), "not a valid cell");
    uint256 deadline = _onchainRounds[_enemy()][cell.id];
    require(block.timestamp < deadline,"out of respond deadline");
    _onchainRounds[_enemy()][cell.id] = type(uint256).max;
    emit FlightClubGame_respondAttack(msg.sender, cell.id, cell.status,cell.nonce);
  }

  function _confirmResult(address player, Result calldata result) private view {
    for (uint256 i = 0; i < 3; i++) {
      Cell calldata cell = result.cells[i];
      if (cell.status != 2 || verifyCell(player, cell, result.proofs[i]) != true) {
        revert FlightClubGame_InvalidTargetCell(cell.id, cell.status);
      }
    }
  }

  function winnerConfirmByResult(Result calldata enemyResult, Result calldata selfResult) public onlyPlayer {
    _confirmResult(msg.sender, selfResult);
    _confirmResult(_enemy(), enemyResult);
    _distributeReward(msg.sender);
  }

  function _checkRaiseProof(RaiseProof calldata raiseProof) private view {
    Attack calldata attack = raiseProof.attack;
    Cell calldata cell = raiseProof.cell;
    bytes32[] calldata attackProof = raiseProof.attackProof;
    bytes32[] calldata cellProof = raiseProof.cellProof;
    if (attack.target != cell.id) {
      revert FlightClubGame_InvalidRaiseProof(raiseProof);
    }
    if (cell.status != 2) {
      revert FlightClubGame_InvalidRaiseProof(raiseProof);
    }
    if (!verifyAttack(_enemy(), attack, attackProof) || !verifyCell(msg.sender, cell, cellProof)) {
      revert FlightClubGame_InvalidRaiseProof(raiseProof);
    }
  }

  function raise(uint256 newBet, RaiseProof calldata raiseProof) public onlyPlayer {
    _checkRaiseProof(raiseProof);
    address enemy = _enemy();
    uint256 cellID = raiseProof.cell.id;
    RaiseProposal memory proposal = _raiseProposals[enemy][cellID];
    if (proposal.deadline != 0) {
      revert FlightClubGame_InvalidRaiseProof(raiseProof);
    }
    proposal.bet = newBet;
    proposal.deadline = block.timestamp + 3 minutes;
    _raiseProposals[enemy][cellID] = proposal;
    emit FlightClubGame_Raise(msg.sender, cellID, newBet);
  }

  function confirmRaise(uint256 cellID) public onlyPlayer {
    RaiseProposal memory proposal = _raiseProposals[msg.sender][cellID];
    if (proposal.deadline > 0 && block.timestamp > proposal.deadline) {
      revert FlightClubGame_TooLateToConfirmRaise(proposal.deadline);
    }
    bet = proposal.bet;
    proposal.deadline = type(uint256).max;
    _raiseProposals[msg.sender][cellID] = proposal;
    emit FlightClubGame_ConfirmRaise(msg.sender, cellID, bet);
  }

  function winnerConfirmByRaise(uint256 cellID) public onlyPlayer {
    RaiseProposal memory proposal = _raiseProposals[msg.sender][cellID];
    uint256 deadline = proposal.deadline;
    if (block.timestamp > deadline) {
      _distributeReward(msg.sender);
    }
  }

  function _distributeReward(address winner) private whenNotEnded {
    address loser = winner == creator ? guest : creator;
    FatToken fatToken = FatToken(payable(_fatTokenAddr));
    SoapToken soapToken = SoapToken(_soapTokenAddr);
    fatToken.transferFrom(loser, winner, bet);
    if (soapToken.isMintable()) {
      soapToken.mint(loser);
    }
    fatToken.undelegate(winner);
    fatToken.undelegate(loser);
    emit FlightClubGame_GameEnded(winner);
    _ended = true;
  }

  function loserConfirm() public onlyPlayer {
    _distributeReward(_enemy());
  }
}
