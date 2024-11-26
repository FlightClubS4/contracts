// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

struct Cell {
  uint8 id;
  uint8 status;
  uint240 nonce;
}

struct Attack {
  uint8 target;
  uint248 nonce;
}

