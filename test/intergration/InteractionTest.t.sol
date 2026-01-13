//SDPX-License-Identifier: MIT;

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {console} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {CreateandFundandAddSubscription} from "script/Interactions.s.sol";
import {RevertingReceiver} from "src/RevertingContract.sol";
import "forge-std/Vm.sol";

contract InteractionsTest is Test{
    uint96 public constant BASEFEE = 0.25 ether;
    uint96 public constant GASPRICE = 1e9;
    int256 public constant WEIPERUNITLINK = 4e15;

    uint96 public constant AMOUNT = 3 ether;

    HelperConfig public helperConfig;
    Raffle public raffle;
    HelperConfig.NetworkConfig public localnetworkConfig;
    
    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        // CreateandFundandAddSubscription createSub = new CreateandFundandAddSubscription(helperConfig);

    }

    function test__IfgetvrfCoordinatorUsingConfigReturnsAddress() public {
        //Arrange 
        address owner = makeAddr("owner");
        CreateandFundandAddSubscription createSub = new CreateandFundandAddSubscription(helperConfig);


        //Act
        vm.prank(owner);
        address correctvrf = createSub.getvrfCoordinatorUsingConfig();
        
        //Assert
        assert( correctvrf == createSub.getvrfCoordinatorUsingConfig());
}

    function test__IfRunFunctionWorks() public {
        //Arrange
        address owner = makeAddr("owner");
        CreateandFundandAddSubscription createSub = new CreateandFundandAddSubscription(helperConfig);

        //Act
        vm.prank(owner);
        (uint64 subId, HelperConfig helperConfig) = createSub.run();

        //Assert
       assert(address(helperConfig) != address(0));  
       assert(subId > 0); 
    }

    function test_BranchInHelperConfig() public {
    // Arrange
    address owner = makeAddr("owner");
    vm.startPrank(owner);

    
    helperConfig.setVRFCoordinator(owner); 

    // Act
    HelperConfig.NetworkConfig memory returnedConfig = helperConfig.AnvilConfig();

    // Assert orgthat it returned what was already set
    assert(returnedConfig.vrfCoordinatorV2 == owner);
}   


function test__RevertingContract() public {
    //Arrange
    RevertingReceiver revertReceiver = new RevertingReceiver();
    address player = makeAddr("player");
    vm.deal(player, 3 ether);

    //Act && Assert
    vm.expectRevert(bytes("nope"));
    vm.prank(player);
    payable(address(revertReceiver)).transfer(1 ether); 
   
}



    }
