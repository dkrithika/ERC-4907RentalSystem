// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {Script} from "forge-std/Script.sol";
import {RentalEscrow} from "../src/RentalEscrow.sol";

import {Asset} from "../src/Asset.sol";
contract DeployRentalEscrow is Script{
address constant SEPOLIA_USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
   function run() external returns (RentalEscrow) {
     string memory privateKeyStr = vm.envString("PRIVATE_KEY");
     uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);
    vm.startBroadcast(deployerPrivateKey);
    Asset asset = new Asset();
    
    //pass the mock to RentalEscrow constructor
    RentalEscrow deployed = new RentalEscrow(SEPOLIA_USDC);
    vm.stopBroadcast();
    return deployed;
}
}