// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

struct RootInfo {
  bytes32 attackRoot;
  bytes32 cellRoot;
}

struct GameInitializeInfo {
  address creator;
  address fatTokenAddr;
  uint256 bet;
  RootInfo creatorRoot;
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

struct RaiseProposal {
  uint256 deadline;
  uint256 bet;
}

struct RaiseProof {
  uint256 cellID;
  bytes32 attackProof;
  bytes32 cellProof;
}

