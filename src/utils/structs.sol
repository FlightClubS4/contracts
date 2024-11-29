// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

struct RootInfo {
  bytes32 attackRoot;
  bytes32 cellRoot;
}

struct GameInitializeInfo {
  address creator;
  address fatTokenAddr;
  address soapTokenAddr;
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

struct OnChainRound {
  uint248 attackNonce;
  uint8 status;
  uint240 cellNonce;
  uint256 deadline;
}

struct RaiseProposal {
  uint256 deadline;
  uint256 bet;
}

struct RaiseProof {
  Attack attack;
  Cell cell;
  bytes32[] attackProof;
  bytes32[] cellProof;
}

struct Result {
  Cell[3] cells;
  bytes32[][3] proofs;
}
