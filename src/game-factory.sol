// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { Game } from "./game.sol";
import { FatToken } from "./fat-token.sol";

contract GameFactory is Initializable, OwnableUpgradeable, UUPSUpgradeable {
  /******************* events *****************/
  event GameCreated(address indexed gameCA, address indexed creator, uint256 bet);
  /********************************************/

  /******************* state ********************/
  address gameImplementation;
  address fatTokenAddr;
  /********************************************/

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address initialOwner, address _fatTokenAddr) initializer public {
    __Ownable_init(initialOwner);
    __UUPSUpgradeable_init();
    fatTokenAddr = _fatTokenAddr;
  }

  function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

  function setGameImpletation(address gameImpl) public onlyOwner {
    gameImplementation = gameImpl;
  }

  /*
   * 创建游戏房间
   */
  function createGame(uint256 bet) public {
    address gameCA = Clones.clone(gameImplementation);
    Game game = Game(gameCA);
    FatToken fatToken = FatToken(fatTokenAddr);
    game.initialize(msg.sender, bet, fatTokenAddr);
    fatToken.delegateTo(gameCA);
    emit GameCreated(gameCA, msg.sender, bet);
  }
}
