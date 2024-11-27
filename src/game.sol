// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { FatToken } from "./fat-token.sol";

contract Game is Initializable {
  enum Status {
    CREATED,
    STARED,
    ENDED,
    ARCHIVED
  }

  struct Cell {
    uint8 id;
    uint8 status;
    uint240 nonce;
  }

  struct Attack {
    uint8 target;
    uint248 nonce;
  }

  struct Root {
    bytes32 cellRoot;
    bytes32 attackRoot;
  }

  /******************* events *****************/
  event FlightClubGame_GuestJoin(address guest);
  /********************************************/

  /******************* state ********************/
  address public creator;
  address public guest;
  address public fatTokenAddr;
  uint256 public bet;
  mapping(address player => Root r) roots;
  mapping(address player => bool confirmed) confirmedRaise;
  /********************************************/

  function initialize(address _creator, uint256 _bet, address _fatTokenAddr) initializer public {
    creator = _creator;
    bet = _bet;
    fatTokenAddr = _fatTokenAddr;
  }

  function join() public {
    FatToken fatToken = FatToken(fatTokenAddr);
    fatToken.delegateTo(address(this));
    emit FlightClubGame_GuestJoin(msg.sender);
  }

  function verifyAttack() public view {

  }

  function verifyCell() public view {

  }

  function raise() public {

  }
}
