// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 deadline = block.timestamp + 30 seconds;
    uint256 public constant threshold = 1 ether;

    event Stake(address staker, uint256 amount);

    modifier stakingEventShouldNotBeCompleted() {
        require(
            !exampleExternalContract.completed(),
            "Staking event is completed!"
        );
        _;
    }

    modifier deadlineShouldBeOver() {
        require(deadline < block.timestamp, "Deadline is not over!");
        _;
    }

    modifier deadlineShouldNotBeOver() {
        require(deadline >= block.timestamp, "Deadline is over!");
        _;
    }

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable deadlineShouldNotBeOver {
        uint256 value = msg.value;
        require(value > 0, "stake amount cannot be zero");
        address sender = msg.sender;
        balances[sender] = value;
        emit Stake(sender, value);
    }

    function timeLeft() external view returns (uint256) {
        return deadline > block.timestamp ? deadline - block.timestamp : 0;
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function execute() external stakingEventShouldNotBeCompleted {
        uint256 total = address(this).balance;
        if (total >= threshold) {
            exampleExternalContract.complete{value: total}();
        }
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    // Add a `withdraw()` function to let users withdraw their balance
    // REF: https://docs.soliditylang.org/en/v0.8.7/common-patterns.html
    function withdraw() external deadlineShouldBeOver stakingEventShouldNotBeCompleted {
        require(address(this).balance < threshold, 'Threshold met, no more withdrawal!');
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No amount available to withdraw!");
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}
