// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20BurnableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/*
 * 游戏筹码token
 */
contract FatToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address upgrader) initializer public {
    __ERC20_init("FatToken", "FAT");
    __Ownable_init(upgrader);
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

  /*
   * 转入eth, 铸造token
   */
  function mint(address to, uint256 amount) public payable {
    // TODO
  }

  /*
   * 销毁token，提取eth
   */
  function burn(address payable to, uint256 amount) public {
    // TODO
  }

  // TODO: 修改update函数，正在进行游戏时不能转账给除了游戏合约之外的其他人
}
