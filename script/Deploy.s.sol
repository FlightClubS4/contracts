// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";
import "../src/game-factory.sol";
import "../src/game.sol";
import {FatToken} from "../src/fat-token.sol";
import {SoapToken} from "../src/soap-token.sol";
import {Upgrades} from "../lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

contract Deploy is Script {

  FatToken public fatToken;
  address payable public fatTokenAddress;

  SoapToken public soapToken;
  address public soapTokenAddress;

  GameFactory public factory;
  address public factoryAddress;


  //arbitrum
  function run() public {

    vm.startBroadcast(vm.envUint("PrivateKey"));
    address admin = vm.addr(vm.envUint("PrivateKey"));

    //fatToken
    bytes memory initData = abi.encodeWithSelector(FatToken.initialize.selector, admin);
    fatTokenAddress = payable(Upgrades.deployUUPSProxy("fat-token.sol:FatToken", initData));
    fatToken = FatToken(fatTokenAddress);

    //soapToken
    initData = abi.encodeWithSelector(SoapToken.init.selector, admin);
    soapTokenAddress = Upgrades.deployUUPSProxy("soap-token.sol:SoapToken", initData);
    soapToken = SoapToken(soapTokenAddress);

    //factory
    initData = abi.encodeWithSelector(GameFactory.initialize.selector, admin, fatTokenAddress, soapTokenAddress);
    factoryAddress = Upgrades.deployUUPSProxy("game-factory.sol:GameFactory", initData);
    factory = GameFactory(factoryAddress);
    Game game = new Game();
    factory.setGameImplementation(address(game));

    //config soapToken
    soapToken.setMintManager(factoryAddress);




    console.log("proxyFatTokenAddress",fatTokenAddress);
    console.log("proxySoapTokenAddress",soapTokenAddress);
    console.log("proxyFactoryAddress",factoryAddress);

    console.log("FatTokenAddress",Upgrades.getImplementationAddress(fatTokenAddress));
    console.log("SoapTokenAddress",Upgrades.getImplementationAddress(soapTokenAddress));
    console.log("FactoryAddress",Upgrades.getImplementationAddress(factoryAddress));
    console.log("gameAddress",address(game));

    vm.stopBroadcast();
  }


}
