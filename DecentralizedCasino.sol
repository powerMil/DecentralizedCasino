/* A decentralized casino */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFV2WrapperConsumerBase} from "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract DecentralizedCasino is VRFV2WrapperConsumerBase {
    mapping(address => uint256) public gameWeiValues;

    address constant LINK_ADDRESS = ""; //input a sepolia testnet - link token
    address constant LINK_WRAPPER_ADDRESS = ""; // input a sepolia testnet - wrapper address link
    address[] public lastThreeWinners;

    uint256 private lastRandomnessRequestId;
    uint256 public random;

    constructor()
        VRFV2WrapperConsumerBase(LINK_ADDRESS, LINK_WRAPPER_ADDRESS)
    {}

    function startGame() public payable {
        require(lastRandomnessRequestId == 0);

        lastRandomnessRequestId = requestRandomness(100000, 3, 1);
        gameWeiValues[msg.sender] = msg.value;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(lastRandomnessRequestId == requestId);
        uint256 randomNumber = randomWords[0];

        random = randomNumber;
        if (randomNumber % 2 == 0) {
            uint256 winningAmount = gameWeiValues[msg.sender] * 2;
            (bool success, ) = msg.sender.call{value: winningAmount}("");
            require(success, "Transfer failed");

            lastThreeWinners.push(msg.sender);
            if (lastThreeWinners.length > 3) {
                lastThreeWinners[0] = lastThreeWinners[1];
                lastThreeWinners[1] = lastThreeWinners[2];
                lastThreeWinners[2] = lastThreeWinners[3];
                lastThreeWinners.pop();
            }
        }
        gameWeiValues[msg.sender] = 0;
        lastRandomnessRequestId = 0;
    }

    receive() external payable {
        startGame();
    }
}
