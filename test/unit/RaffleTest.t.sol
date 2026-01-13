//SPDX-License_Identifier : MIT;

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {console} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import "forge-std/Vm.sol";
import {RevertingReceiver} from "src/RevertingContract.sol";

contract RaffleTest is Script, Test {
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
    error Raffle__TransferFailed();
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__RaffleNotOpen();

    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed player);

    uint96 public constant AMOUNT = 3 ether;
    Raffle raffle;
    HelperConfig helperConfig;
    DeployRaffle deployRaffle;
    Raffle.RaffleState public s_raffleState;
    uint256 public s_lastTimeStamp;
    uint256 i_interval;
    uint64 subId;
    address vrfCoordinator;
    uint256 entranceFee;

    function setUp() public {
        address player = makeAddr("player");
        vm.deal(player, 25 ether);
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployRaffle();

        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getlocalnetworkConfig();
        vrfCoordinator = networkConfig.vrfCoordinatorV2;
        subId = uint64(networkConfig.subscriptionId);
        i_interval = networkConfig.interval;
        (,, address subOwner,) = VRFCoordinatorV2Mock(vrfCoordinator).getSubscription(subId);
        entranceFee = networkConfig.entranceFee;

        vm.startPrank(subOwner);
        // VRFCoordinatorV2Mock(vrfCoordinator). fundSubscription(subId, AMOUNT);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, address(raffle));
        vm.stopPrank();
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
        assertEq(rafflebalanceafter, 2 ether, "Correct Amount of Ether sent");
        assertEq(playerbalance, 23 ether, "Correct Amount of Ether Deducted");
    }

    function test__EnterRaffleWithOutEnoughEther() public {
        //Arrange
        address player = makeAddr("player");
        vm.deal(player, 25 ether);
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
        vm.deal(anotherplayer, 10 ether);
        vm.prank(player);
        raffle.enterRaffle{value: 2 ether}();

        vm.deal(address(raffle), 10 ether);
        uint256 rafflebalance = address(raffle).balance;
        console.log("Raffle Balance before entering", rafflebalance);
        vm.warp(block.timestamp + raffle.getInterval() + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //Act && Assert

        vm.expectRevert(Raffle__RaffleNotOpen.selector);
        vm.prank(anotherplayer);
        raffle.enterRaffle{value: 2 ether}();
    }

    function test_ifEmitHappensOnCallingEnterRaffle() public {
        //Arrange
        address player = makeAddr("player");
        vm.expectEmit(true, false, false, false);
        emit RaffleEnter(player);

        //Act && Assert
        vm.prank(player);
        raffle.enterRaffle{value: 2 ether}();
    }

    ///////////////////////////////////////////////////////
    //////////////////CHECKUPKEEP ////////////////////////
    ///////////////////////////////////////////////////////

    modifier raffleSetToOpen() {
        raffle.setRaffleState(Raffle.RaffleState.OPEN);
        _;
    }

    function test__checkUpKeepReturnsFalseWhenTimeHasntPassed() public raffleSetToOpen {
        //Arrange
        address player = makeAddr("player");
        vm.deal(player, 2 ether);
        vm.prank(player);
        raffle.enterRaffle{value: 2 ether}();

        vm.warp(block.timestamp + raffle.getInterval() - 4);
        vm.roll(block.number + 1);
        vm.deal(address(raffle), 25 ether);

        //Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("0x0");

        //Assert
        assertEq(upkeepNeeded, false);
    }

    function test__checkUpKeepReturnsFalseWhenRaffleHasNoBalance() public raffleSetToOpen {
        //Arrange

        vm.warp(block.timestamp + raffle.getInterval() + 1);
        vm.roll(block.number + 1);
        vm.deal(address(raffle), 0 ether);

        //Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("0x0");

        //Assert
        assertEq(upkeepNeeded, false);
    }

    function test__checkUpKeepReturnsFalseWhenRaffleHasNoPlayers() public raffleSetToOpen {
        //Arrange
        vm.warp(block.timestamp + raffle.getInterval() + 1);
        vm.roll(block.number - 1);
        vm.deal(address(raffle), 25 ether);

        //Act
        //Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("0x0");

        //Assert
        assertEq(upkeepNeeded, false);
    }

    /////////////////////////////////////////////////////////
    //////////////////PERFORMUPKEEP/////////////////////////
    ////////////////////////////////////////////////////////

    function test__IfPerformUpkeepRunWhenParametersAreTrue() public raffleSetToOpen {
        //Arrange
        address player = makeAddr("player");
        vm.deal(player, 14 ether);
        vm.prank(player);
        raffle.enterRaffle{value: 2 ether}();
        vm.warp(block.timestamp + raffle.getInterval() + 1);
        vm.deal(address(raffle), 24 ether);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = raffle.checkUpkeep("0x0");

        //Act && Assert
        assertEq(upkeepNeeded, true);
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestId = entries[0].topics[1];

        assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.CALCULATING));
        (bool upkeepNeededafter,) = raffle.checkUpkeep("0x0");
        assertEq(upkeepNeededafter, false);
        assert(requestId != bytes32(0));
    }

    function test__performUpkeepRevertAsExpected() public {
        //Arrange
        vm.warp(block.timestamp + raffle.getInterval() - 1);
        vm.deal(address(raffle), 24 ether);
        vm.roll(block.number + 1);

        (bool upkeepNeeded,) = raffle.checkUpkeep("0x0");

        //Act && Assert

        assert(upkeepNeeded != true);
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                address(raffle).balance,
                raffle.getNumberOfPlayers(),
                uint256(raffle.getRaffleState())
            )
        );
        raffle.performUpkeep("");
    }

    /////////////////////////////////////////////////////////
    ///////////////////////fulfillRandomWords////////////////
    /////////////////////////////////////////////////////////
    
    function test__IfFullfillRandomWordsWillEmitWinner() public raffleSetToOpen{
        //Arrange 
        address player = makeAddr("player");
        vm.deal(player, 14 ether);
        vm.prank(player);
        raffle.enterRaffle{value: 2 ether}();
        vm.warp(block.timestamp + raffle.getInterval() + 1);
        vm.deal(address(raffle), 24 ether);
        vm.roll(block.number + 1);
        raffle.checkUpkeep("0x0");
    
        raffle.performUpkeep("");
        
        uint256 requestId = raffle.getRequestId();
        //Act && Assert
        vm.expectEmit(true, false, false , false);
         emit WinnerPicked(player);
       
        vm.startPrank(vrfCoordinator);
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(requestId, address(raffle));
        vm.stopPrank();
}

 function test__IfFullfillRandomWordsWillTransferBalanceToWInner() public raffleSetToOpen{
    //Arrange
     address player = makeAddr("player");
        vm.deal(player, 14 ether);
        vm.prank(player);
        raffle.enterRaffle{value: 2 ether}();
        vm.warp(block.timestamp + raffle.getInterval() + 1);
        vm.deal(address(raffle), 24 ether);
        vm.roll(block.number + 1);
        raffle.checkUpkeep("0x0");
    
        raffle.performUpkeep("");

    uint256 requestId = raffle.getRequestId();
    

    vm.startPrank(vrfCoordinator);
    VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords( requestId, address(raffle));
    vm.stopPrank();

    address recentWinner = raffle.getRecentWinner();

    //Act && Assert
    assertEq(recentWinner.balance , 36 ether);
     }

    //  function test__IfFullfillRandomWordsWillRevert() public raffleSetToOpen{
    //     //Arrange
    //     RevertingReceiver revertContract = new RevertingReceiver();
    //     vm.deal(address(revertContract), 14 ether);
    //     vm.prank(address(revertContract));
    //     raffle.enterRaffle{value: 2 ether}();
    //     vm.warp(block.timestamp + raffle.getInterval() + 1);
    //     vm.deal(address(raffle), 24 ether);
    //     vm.roll(block.number + 1);
    //     raffle.checkUpkeep("0x0");
    
    //     raffle.performUpkeep("");

    // uint256 requestId = raffle.getRequestId();
    
    
    // vm.startPrank(vrfCoordinator);
    // vm.expectRevert(Raffle.Raffle__TransferFailed.selector);
    // VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords( requestId, address(raffle));
    // vm.stopPrank();

        
    //  }

    function test__TestTheGetterFunctions() public {
    address player = makeAddr("player");
    vm.deal(player, 6 ether);
    vm.prank(player);
    raffle.enterRaffle{value : 6 ether}();

    uint256 realNumWords = raffle.getNumWords();
    uint256 realgetRequestConfirmations = raffle.getRequestConfirmations();
    address realgetRecentWinner = raffle.getRecentWinner();
    address realgetPlayer = raffle.getPlayer(0);
    uint256 realgetLastTImeStamp = raffle.getLastTimeStamp();
    uint256 realgetEntranceFee = raffle.getEntranceFee();

    assertEq(raffle.getNumWords(), 1);
    assertEq(raffle.getRequestConfirmations(), 3);
    assertEq(raffle.getRecentWinner(), address(0));
    assertEq(raffle.getPlayer(0), address(player)); // if only the test contract entered
    assertEq(raffle.getLastTimeStamp(), raffle.getLastTimeStamp()); // or expected timestamp
    assertEq(raffle.getEntranceFee(), 2 ether);
    }

}
