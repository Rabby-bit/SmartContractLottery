//SPDX-LIcense-Identifier: MIT

pragma solidity ^0.8.29;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract Constants {
    //Mock Constant
    uint96 public constant BASEFEE = 0.25 ether;
    uint96 public constant GASPRICE = 1e9;
    int256 public constant WEIPERUNITLINK = 4e15;

    //Chain ID
    uint256 public constant SEPOLIA_CHAINID = 11155111;
    uint256 public constant zKSYNC_CHAINID = 300;
    uint256 public constant LOCAL_CHAINID = 31337;
}

contract HelperConfig is Script, Constants {
    NetworkConfig public networkConfig;

    struct NetworkConfig {
        uint256 subscriptionId;
        bytes32 gasLane; // keyHash
        uint256 interval;
        uint256 entranceFee;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2;
    }

    error HelperConfig__ChainNotSupporter();

    constructor() {
        if (block.chainid == SEPOLIA_CHAINID) {
            networkConfig = SepoliaConfig();
        } else if (block.chainid == zKSYNC_CHAINID) {
            networkConfig = zkSyncConfig();
        } else if (block.chainid == LOCAL_CHAINID) {
            networkConfig = AnvilConfig();
        } else {
            revert HelperConfig__ChainNotSupporter();
        }
    }

    function SepoliaConfig() public returns (NetworkConfig memory) {
      NetworkConfig memory SepConfig = NetworkConfig 
        ( {
         subscriptionId : 0,
         gasLane : 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
         interval : 30,
         entranceFee : 1 ether,
         callbackGasLimit : 150_000,
         vrfCoordinatorV2 : address(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B) }
        )
      ;
      return SepConfig;
    }

    function zkSyncConfig() public returns (NetworkConfig memory) {}

    function AnvilConfig() public returns (NetworkConfig memory) {}
}
