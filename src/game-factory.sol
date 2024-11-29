// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { Game } from "./game.sol";
import { FatToken } from "./fat-token.sol";
import { SoapToken } from "./soap-token.sol";
import { GameInitializeInfo, RootInfo } from "./utils/structs.sol";

contract GameFactory is Initializable, OwnableUpgradeable, UUPSUpgradeable {
  /******************* events *****************/
  event FlightClub_GameCreated(address indexed gameCA, address indexed creator, uint256 bet);
  /********************************************/

  /******************* state ********************/
  address private _gameImplementation;
  address private _fatTokenAddr;
  address private _soapTokenAddr;
  /********************************************/

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address initialOwner, address fatTokenAddr, address soapTokenAddr) initializer public {
    __Ownable_init(initialOwner);
    __UUPSUpgradeable_init();
    _fatTokenAddr = fatTokenAddr;
    _soapTokenAddr = soapTokenAddr;
  }

  function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

  function setGameImplementation(address gameImpl) public onlyOwner {
    _gameImplementation = gameImpl;
  }

  /*
   * 创建游戏房间
   */
  function createGame(uint256 bet, RootInfo calldata creatorRoot) public {
    address gameCA = Clones.clone(_gameImplementation);
    Game game = Game(gameCA);
    GameInitializeInfo memory initializeInfo = GameInitializeInfo({
      creator: msg.sender,
      bet: bet,
      fatTokenAddr: _fatTokenAddr,
      soapTokenAddr: _soapTokenAddr,
      creatorRoot: creatorRoot
    });
    game.initialize(initializeInfo);
    SoapToken soapToken = SoapToken(_soapTokenAddr);
    soapToken.setMinter(gameCA);
    emit FlightClub_GameCreated(gameCA, msg.sender, bet);
  }
}
