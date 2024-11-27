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
  /******************* errors *****************/
  error FatToken_InvalidOperator(address validOperator, address operator);
  /********************************************/

  /******************* events *****************/

  /********************************************/

  /******************* state ********************/
  mapping(address tokenOwner => address gameCA) private _delegateTo;
  /********************************************/


  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address initialOwner) initializer public {
    __ERC20_init("FatToken", "FAT");
    __Ownable_init(initialOwner);
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

  function _update(address from, address to, uint256 value) internal override {
    address delegator = _delegateTo[from];
    if (delegator == address(0) || delegator == msg.sender) {
      super._update(from, to, value);
    } else {
      revert FatToken_InvalidOperator(delegator, msg.sender);
    }
  }

  function _approve(address owner, address spender, uint256 value, bool emitEvent) internal override {
    address delegator = _delegateTo[owner];
    if (delegator == address(0) || delegator == msg.sender) {
      super._approve(owner, spender, value, emitEvent);
    } else {
      revert FatToken_InvalidOperator(delegator, msg.sender);
    }
  }

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

  /*
   * 玩家 (tx.origin) 将代币全部 approve 给 delegator，且仅允许 delegator 转移代币
   */
  function delegateTo(address delegator) public {
    _approve(tx.origin, delegator, type(uint256).max);
    _delegateTo[tx.origin] = delegator;
  }

  /*
   * delegator 释放代理操作权限
   */
  function undelegate(address to) public {
    address delegator = _delegateTo[to];
    if (delegator == msg.sender) {
      delete _delegateTo[to];
    } else {
      revert FatToken_InvalidOperator(delegator, msg.sender);
    }
  }
}
