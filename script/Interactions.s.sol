//SPDX-License-Identifier : MIT;

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {console} from "forge-std/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkToken} from "test/intergration/LinkToken.sol";

contract CreateSubscription is Script {
    uint96 public constant BASEFEE = 0.25 ether;
    uint96 public constant GASPRICE = 1e9;
    int256 public constant WEIPERUNITLINK = 4e15;

    uint96 public constant AMOUNT = 3 ether;

    HelperConfig helperConfig;
    Raffle raffle;

    function getvrfCoordinatorUsingConfig() public returns (address) {
        //HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getlocalnetworkConfig();
        VRFCoordinatorV2Mock vrfCoordinator = VRFCoordinatorV2Mock(networkConfig.vrfCoordinatorV2);
        helperConfig.setVRFCoordinator(vrfCoordinator);
        return address(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64 subId) {
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        //HelperConfig helperConfig = new HelperConfig;
        helperConfig.setSubscriptionId(subId);
        vm.stopBroadcast();

        return subId;
    }

    function run() external returns (uint64) {
        address vrfCoordinator = getvrfCoordinatorUsingConfig();
        return createSubscription(vrfCoordinator);
    }
}

contract FundSubscription is Script {
    // uint94 public constant AMOUNT = 4 ether;
    uint96 public constant AMOUNT = 3 ether;

    HelperConfig helperConfig;

    function fundSubscription() public {
        uint64 subId = uint64(helperConfig.getlocalnetworkConfig().subscriptionId);
        address vrfCoordinator = helperConfig.getlocalnetworkConfig().vrfCoordinatorV2;

        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, AMOUNT);
        vm.stopBroadcast();
    }

    function run() external {
        uint64 subId = uint64(helperConfig.getlocalnetworkConfig().subscriptionId);
        address vrfCoordinator = helperConfig.getlocalnetworkConfig().vrfCoordinatorV2;
        fundSubscription();
    }
}

contract AddConsumer is Script {
    HelperConfig helperConfig;
    Raffle raffle;

    function addConsumer() public {
        Raffle raffle = new Raffle();
        address newRaffle = address(raffle);

        uint64 subId = uint64(helperConfig.getlocalnetworkConfig().subscriptionId);
        address vrfCoordinator = helperConfig.getlocalnetworkConfig().vrfCoordinatorV2;

        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, newRaffle);
        vm.stopBroadcast();
    }

    function run() external {
        addConsumer();
    }
}
