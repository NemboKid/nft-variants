// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {CoolToken} from "../src/CoolToken.sol";
import {NFTMaxSupply} from "../src/NFTMaxSupply.sol";

contract DeployCoolToken is Script {
    function run(address _admin) external returns (CoolToken) {
        vm.startBroadcast(_admin);
        CoolToken token = new CoolToken();
        vm.stopBroadcast();
        return token;
    }
}

contract DeployNFTMaxSupply is Script {
    function run(address _admin) external returns (NFTMaxSupply) {
        vm.startBroadcast(_admin);
        // TODO: insert merkle root
        NFTMaxSupply token = new NFTMaxSupply(bytes32("0x"));
        vm.stopBroadcast();
        return token;
    }
}
