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

contract CreateandFundSubscription is Script {
    uint96 public constant BASEFEE = 0.25 ether;
    uint96 public constant GASPRICE = 1e9;
    int256 public constant WEIPERUNITLINK = 4e15;

    uint96 public constant AMOUNT = 3 ether;

    HelperConfig public helperConfig;
    Raffle raffle;

    function getvrfCoordinatorUsingConfig() public returns (address) {
        //HelperConfig helperConfig = new HelperConfig();
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getlocalnetworkConfig();
        VRFCoordinatorV2Mock vrfCoordinatorV2 = VRFCoordinatorV2Mock(networkConfig.vrfCoordinatorV2);
        helperConfig.setVRFCoordinator(address(vrfCoordinatorV2));
        return address(vrfCoordinatorV2);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64 subId) {
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        //HelperConfig helperConfig = new HelperConfig;
        helperConfig.setSubscriptionId(subId);
        vm.stopBroadcast();

        return subId;
    }

    function fundSubscription() public {
        uint64 subId = uint64(helperConfig.getlocalnetworkConfig().subscriptionId);
        address vrfCoordinator = helperConfig.getlocalnetworkConfig().vrfCoordinatorV2;

        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId, AMOUNT);
        vm.stopBroadcast();
    }

    function run() external returns (uint64, HelperConfig) {
        address vrfCoordinator = getvrfCoordinatorUsingConfig();
        uint64 subId = createSubscription(vrfCoordinator);
        fundSubscription();
        return (subId, helperConfig);
        // fundSubscription();
    }
}

contract AddConsumer is Script {
    HelperConfig helperConfig;
    Raffle raffle;

    function addConsumer() public {
        DeployRaffle deployer = new DeployRaffle();
        (Raffle newRaffle,) = deployer.deployRaffle();

        uint64 subId = uint64(helperConfig.getlocalnetworkConfig().subscriptionId);
        address vrfCoordinator = helperConfig.getlocalnetworkConfig().vrfCoordinatorV2;

        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, address(newRaffle));
        vm.stopBroadcast();
    }

    function run() external {
        addConsumer();
    }
}
