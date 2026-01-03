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


    function createSubUsingMock() public returns(uint64 subId) {

       
       HelperConfig helperConfig = new HelperConfig();
       HelperConfig.NetworkConfig memory networkConfig = helperConfig.getlocalnetworkConfig(); 
     VRFCoordinatorV2Mock vrfCoordinatorV2Mock = VRFCoordinatorV2Mock(payable(networkConfig.vrfCoordinatorV2));

       uint64 subId = vrfCoordinatorV2Mock.createSubscription();

       return subId;
       

        
    }

    function createSubscriptionTestnet() public returns (uint64 subId) {
        DeployRaffle deployer = new DeployRaffle();
        (raffle , helperConfig) = deployer.deployRaffle();


        HelperConfig.NetworkConfig memory config =  helperConfig.getlocalnetworkConfig();
        uint64 subId = VRFCoordinatorV2Interface(config.vrfCoordinatorV2)
        .createSubscription();
        return subId;


    }
}
    contract FundSubscription is Script {
    function fundSubscriptionUsingMock(uint64 subId, uint96 AMOUNT ) public {
        if(subId == 0) {
            CreateSubscription createSub = new CreateSubscription();
           uint64 subId = createSub.createSubUsingMock();
        }
        VRFCoordinatorV2Mock.fundSubscription(subId, AMOUNT);


    }
    function fundSubscriptionUsingTestNet(uint64 subId, uint96 AMOUNT ) public {
        if(subId == 0) {
           CreateSubscription createSub = new CreateSubscription();
           uint64 subId = createSub.createSubscriptionTestnet(); 
        }
        DeployRaffle deployer = new DeployRaffle();
        (raffle , helperConfig) = deployer.deployRaffle();
        
        HelperConfig.NetworkConfig memory config =  helperConfig.getlocalnetworkConfig();
        VRFCoordinatorV2Interface(config.vrfCoordinatorV2).createSubscription();



        


    }
    }


