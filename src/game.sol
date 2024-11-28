// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { FatToken } from "./fat-token.sol";
import { RootInfo, Attack, Cell, GameInitializeInfo, RaiseProposal, RaiseProof } from "./utils/structs.sol";

contract Game is Initializable {
  /******************** errors ****************/
  error FlightClubGame_OnlyPlayerCanOperate(address operator, address creator, address guest);
  /********************************************/

  /******************* events *****************/
  event FlightClubGame_GuestJoin(address guest);
  event FlightClubGame_Raise(address raiser, uint256 cellID, uint256 bet);
  event FlightClubGame_ConfirmRaise(address confirmer, uint256 cellID, uint256 bet);
  event FlightClubGame_WinnerConfirmed(address winner);
  /********************************************/

  /******************* state *******************/
  address public creator;
  address public guest;
  address public fatTokenAddr;
  uint256 public bet;
  mapping(address player => RootInfo r) private _roots;
  mapping(address attacker => mapping(uint256 cellID =>  RaiseProposal)) private _raiseProposals;

  /********************************************/

  /******************** modifier **************/
  modifier onlyPlayer() {
    if (msg.sender != creator || msg.sender != guest) {
      revert FlightClubGame_OnlyPlayerCanOperate(msg.sender, creator, guest);
    }
    _;
  }
  /********************************************/

  function initialize(GameInitializeInfo calldata info) initializer public {
    creator = info.creator;
    bet = info.bet;
    fatTokenAddr = info.fatTokenAddr;
    _roots[creator] = info.creatorRoot;
    FatToken fatToken = FatToken(fatTokenAddr);
    fatToken.delegateTo(address(this));
  }

  function _enemy() private view returns(address) {
    return msg.sender == creator ? guest : creator;
  }

  function join(RootInfo calldata root) public {
    FatToken fatToken = FatToken(fatTokenAddr);
    guest = msg.sender;
    _roots[msg.sender] = root;
    fatToken.delegateTo(address(this));
    emit FlightClubGame_GuestJoin(msg.sender);
  }

  function verifyAttack(address attacker, Attack calldata attack, bytes32[] calldata proof) public view returns(bool) {
    // TODO
    return true;
  }

  function verifyCell(address enemey, Cell calldata cell, bytes32[] calldata proof) public view returns(bool) {
    // TODO
    return true;
  }

  function _checkRaiseProof(RaiseProof memory raiseProof) private pure returns(bool) {
    // TODO
    return true;
  }

  function raise(uint256 newBet, RaiseProof memory raiseProof) public onlyPlayer {
    _checkRaiseProof(raiseProof);
    uint256 cellID = raiseProof.cellID;
    RaiseProposal memory proposal = _raiseProposals[_enemy()][cellID];
    proposal.bet = newBet;
    proposal.deadline = block.timestamp + 3 minutes;
    _raiseProposals[_enemy()][cellID] = proposal;
    emit FlightClubGame_Raise(msg.sender, cellID, newBet);
  }

  function _checkRaiseConfirmation(uint256 cellID) private pure returns(bool) {
    // TODO
    return true;
  }

  function confirmRaise(uint256 cellID) public onlyPlayer {
    _checkRaiseConfirmation(cellID);
    RaiseProposal memory proposal = _raiseProposals[msg.sender][cellID];
    bet = proposal.bet;
    proposal.deadline = type(uint256).max;
    _raiseProposals[msg.sender][cellID] = proposal;
    emit FlightClubGame_ConfirmRaise(msg.sender, cellID, bet);
  }

  function confirmWinner(Cell[3] calldata cellInfos) public onlyPlayer {
    // TODO
    emit FlightClubGame_WinnerConfirmed(msg.sender);
  }

  function confirmWinner(uint256 cellID) public onlyPlayer {
    RaiseProposal memory proposal = _raiseProposals[msg.sender][cellID];
    uint256 deadline = proposal.deadline;
    if (block.timestamp > deadline) {
      // TODO
      emit FlightClubGame_WinnerConfirmed(msg.sender);
    }
  }

  function confirmLoser() public onlyPlayer {
    // TODO: 领soap token
    emit FlightClubGame_WinnerConfirmed(_enemy());
  }
}
