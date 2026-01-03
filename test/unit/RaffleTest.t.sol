//SPDX-License_Identifier : MIT;

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {console} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";

contract RaffleTest is Script, Test {

    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
    error Raffle__TransferFailed();
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__RaffleNotOpen();
    Raffle raffle;
    HelperConfig helperConfig;
    DeployRaffle deployRaffle;
    Raffle.RaffleState public s_raffleState;
    uint256 public s_lastTimeStamp;
    uint256 i_interval;

    function setUp() public {
     address player = makeAddr("player");
     vm.deal(player, 25 ether);
     DeployRaffle deployer = new DeployRaffle();
     ( raffle, helperConfig ) = deployer.deployRaffle();
     }

     function test__EnterRaffleWithCorrectAmountOfEther() public {
        //Arrange
        address player = makeAddr("player");
        s_raffleState = Raffle.RaffleState.OPEN;
        uint256 rafflebalance = address(raffle).balance;
        console.log("Raffle Balance before entering", rafflebalance);
        //Act
        vm.prank(player);
        raffle.enterRaffle{value: 2 ether}();
        uint256 playerbalance = player.balance;
        uint256 rafflebalanceafter = address(raffle).balance;

        //Assert
        assertEq(rafflebalanceafter , 2 ether, "Correct Amount of Ether sent");
        assertEq(playerbalance, 23 ether, "Correct Amount of Ether Deducted");

     }

     function test__EnterRaffleWithOutEnoughEther () public {
        //Arrange
        address player = makeAddr("player");
        s_raffleState = Raffle.RaffleState.OPEN;
        uint256 rafflebalance = address(raffle).balance;
        console.log("Raffle Balance before entering", rafflebalance);
        //Act &&Assert
        vm.expectRevert(Raffle__SendMoreToEnterRaffle.selector);
        vm.prank(player);
        raffle.enterRaffle{value: 0 ether}();
        
        
        
     }

     function test__RaffleRevertWhenStateIsCalculating() public {
        //Arrange
        address player = makeAddr("player");
        //s_raffleState = Raffle.RaffleState.CALCULATING;
        // this doesnt chage the state only performUpkeep will
        address anotherplayer = makeAddr("anotherplayer");
        vm.prank(player);
        raffle.enterRaffle{value: 2 ether}();

        vm.deal(address(raffle), 10 ether);
        uint256 rafflebalance = address(raffle).balance;
        console.log("Raffle Balance before entering", rafflebalance);
        vm.warp(block.timestamp +  raffle.getInterval()  + 1);

        

        raffle.performUpkeep("");

        //Act && Assert

        vm.expectRevert(Raffle__RaffleNotOpen.selector);
        vm.prank(player);
        raffle.enterRaffle{value: 2 ether}();
       
        

     }

}
