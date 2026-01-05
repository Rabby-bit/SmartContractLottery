//SPDX-License_Identifier : MIT;

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {console} from "forge-std/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {CreateandFundandAddSubscription} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    /**
     * Adding deployRaffle and run function make it easy for test to call script logic with out calling run()
     */
    function deployRaffle() public returns (Raffle, HelperConfig) {
        vm.startBroadcast();
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getlocalnetworkConfig();

        CreateandFundandAddSubscription interactions = new CreateandFundandAddSubscription();

        address vrfCoordinator = interactions.getvrfCoordinatorUsingConfig();

        uint64 subId = interactions.createSubscription(vrfCoordinator);

        interactions.fundSubscription();

        Raffle raffle = new Raffle(
            subId, config.gasLane, config.interval, config.entranceFee, config.callbackGasLimit, config.vrfCoordinatorV2
        );
        vm.stopBroadcast();
        interactions.addConsumer();

        return (raffle, helperConfig);
    }

    function run() public returns (Raffle, HelperConfig) {
        return deployRaffle();
    }
}
