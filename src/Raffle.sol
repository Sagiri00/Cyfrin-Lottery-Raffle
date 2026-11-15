// SPDX-License-Identifier: MIT

// Layout of Contract:
// license
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.5.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

/**
 * @title Raffle
 * @author Shubham
 * @notice This contract allows users to participate in a raffle by entering with a specified amount of Ether. A winner is randomly selected from the participants after the raffle ends.
 * @dev A simple raffle contract that allows users to enter a raffle and randomly selects a winner.
 * @dev Implement chainlink VRF for randomness in the future.
 */
contract Raffle is VRFConsumerBaseV2Plus {


    /**
     * Custom Errors
     */
    error Raffle__NotEnoughEthEntered();
    error Raffle__TransferFailed();
    error Raffle__NotEnoughTimePassed();
    error Raffle__CannotEnter();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);


    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }



    /* State Variables */

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    // Chainlink VRF related variables
    // VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    // IVRFCoordinatorV2Plus private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint256 private s_raffleState;
  

    // What data strcture should we use to store the players? Dynamic array of addresses
    address payable[] private s_players;

    /* Events */
    // Events are used to log information on the blockchain, which can be useful for tracking contract activity and debugging.
    // Events are cheaper than storing data on the blockchain, as they do not require storage space and can be indexed for easy searching.
    // Events are also useful for triggering off-chain actions, such as sending notifications or updating user interfaces.
    // Events are not accessible from within the contract, but they can be accessed by external applications that listen for them.
    // Events are not stored on the blockchain, but they are stored in the transaction logs, which can be accessed by external applications.
    // Events are not guaranteed to be emitted, as they can be filtered out by the EVM if the transaction fails or is reverted.
    // We use Events eveerytime the State of the contract changes or when we update something on the blockchain, so that we can track the changes and debug the contract easily.
    event RaffleEntered(address indexed player, uint256 indexed amount);
    event WinnerSelected(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint256 _subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        // s_vrfCoordinator.requestRandomWords;
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = uint256(RaffleState.OPEN);
    }

    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH entered"); #This is not very Gas efficient, so we will use custom errors instead of require statements with strings.
        // require(msg.value < i_enteranceFee, Raffle__NotEnoughEthEntered()); #This is not very Gas efficient, also this require V.I.R which takes a lot of time to compile and also it is available in Solidity version 0.8.26 and above.

        if (RaffleState(s_raffleState) != RaffleState.OPEN) {
            revert Raffle__CannotEnter();
        }

        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthEntered();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender, msg.value);
    }

    /**
     * @dev This function is called by Chainlink Keepers to check if the raffle needs to be updated. It checks if enough time has passed since the last raffle and if there are any players in the raffle. If both conditions are met, it returns true, indicating that upkeep is needed.
     * @notice Checks if the raffle needs to be updated
        * @return upkeepNeeded A boolean indicating whether upkeep is needed
    */
    function checkUpKeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool isOpen = RaffleState(s_raffleState) == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    // 1. Function to select a winner from the list of players
    // 2. Function to transfer the prize money to the winner
    // 3. Function to reset the raffle for the next round

    function performUpkeep(bytes memory /* performData */) public {
        (bool upkeepNeeded, ) = checkUpKeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        // We are going to check if the raffle is open or not, if it is open then we can select a winner, if it is not open then we cannot select a winner.
        s_raffleState = uint256(RaffleState.CALCULATING);
        
        
        // Request random number from Chainlink VRF

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_gasLane,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
    });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    // CEI (Checks-Effects-Interactions) pattern is a best practice in Solidity to prevent reentrancy attacks. It involves performing all checks first, then updating state variables, and finally interacting with external contracts or sending Ether.

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {

        // Checks
        // Check if the raffle is in the calculating state

        //Effects
        // Select a winner from the list of players using the random number provided by Chainlink VRF
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];

        s_raffleState = uint256(RaffleState.OPEN);
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerSelected(winner);

        // Interactions (Other contracts or sending Ether)
        // Transfer the prize money to the winner
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /** 
     * Getter Functions
     */
    /**
     * @notice Returns the entrance fee for the raffle
     * @return The entrance fee
     */

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}


