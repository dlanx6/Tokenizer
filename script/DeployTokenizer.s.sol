// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Tokenizer} from "../src/Tokenizer.sol";

contract DeployTokenizer is Script {
    /**
     * @dev deploys the contract
     * @return Instance of Tokenizer contract
     */
    function run() external returns (Tokenizer) {
        address owner = vm.envAddress("OWNER_ADDRESS");

        vm.startBroadcast();
        Tokenizer tokenizer = new Tokenizer(owner);
        vm.stopBroadcast();

        return tokenizer;
    }
}
