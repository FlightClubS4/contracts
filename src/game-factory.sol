// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract GameFactory is Initializable, OwnableUpgradeable, UUPSUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address upgrader) initializer public {
    __Ownable_init(upgrader);
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

  /*
   * 创建游戏房间
   */
  function createGame() public {
    // TODO
  }
}
