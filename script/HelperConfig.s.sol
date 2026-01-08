//SPDX-LIcense-Identifier: MIT

pragma solidity ^0.8.29;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

abstract contract Constants {
    //Mock Constant
    uint96 public constant BASEFEE = 0.25 ether;
    uint96 public constant GASPRICE = 1e9;
    int256 public constant WEIPERUNITLINK = 4e15;

    //Chain ID
    uint256 public constant SEPOLIA_CHAINID = 11155111;
    uint256 public constant LOCAL_CHAINID = 31337;
}

contract HelperConfig is Script, Constants {
    NetworkConfig public localnetworkConfig;

    struct NetworkConfig {
        uint256 subscriptionId;
        bytes32 gasLane; // keyHash
        uint256 interval;
        uint256 entranceFee;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2;
    }

    error HelperConfig__ChainNotSupporter();

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAINID] = SepoliaConfig();
        networkConfigs[LOCAL_CHAINID] = AnvilConfig();

        // if (block.chainid == SEPOLIA_CHAINID) {
        //     localnetworkConfig = SepoliaConfig();
        // } else if (block.chainid == LOCAL_CHAINID) {
        //     localnetworkConfig = AnvilConfig();
        // } else {
        //     revert HelperConfig__ChainNotSupporter();
        // }
    }

    function SepoliaConfig() public returns (NetworkConfig memory) {
        NetworkConfig memory SepConfig = NetworkConfig({
            subscriptionId: 80622678660144973197869773136185095184844476511147031463111626283704941619782,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            interval: 30,
            entranceFee: 2 ether,
            callbackGasLimit: 150_000,
            vrfCoordinatorV2: address(0)
        });

        localnetworkConfig = SepConfig;

        return SepConfig;
    }

    function AnvilConfig() public returns (NetworkConfig memory) {
        if (localnetworkConfig.vrfCoordinatorV2 != address(0)) {
            return localnetworkConfig;
        }

        VRFCoordinatorV2Mock vrfCoordinatorV2_5Mock = new VRFCoordinatorV2Mock(BASEFEE, GASPRICE);
        NetworkConfig memory LocalConfig = NetworkConfig({
            subscriptionId: 1,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            interval: 30,
            entranceFee: 2 ether,
            callbackGasLimit: 150_000,
            vrfCoordinatorV2: address(vrfCoordinatorV2_5Mock)
        });

        localnetworkConfig = LocalConfig;

        return LocalConfig;
    }

    function getlocalnetworkConfig() public view returns (NetworkConfig memory) {
        NetworkConfig memory configCopy = localnetworkConfig; // copy from storage to memory
        return configCopy;
    }

    function setSubscriptionId(uint256 _subId) external {
        localnetworkConfig.subscriptionId = _subId;
    }

    function setVRFCoordinator(address vrfCoordinatorV2) external {
        localnetworkConfig.vrfCoordinatorV2 = vrfCoordinatorV2;
    }
}
