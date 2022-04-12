pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    uint256 public constant tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(
        address seller,
        uint256 amountOfETH,
        uint256 amountOfTokens
    );

    YourToken public yourToken;

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    function buyTokens() public payable {
        uint256 amountOfETH = msg.value;
        uint256 amountOfTokens = amountOfETH * tokensPerEth;
        bool isTransferred = yourToken.transfer(
            payable(msg.sender),
            amountOfTokens
        );
        require (isTransferred, "Transfer of tokens failed!");
        emit BuyTokens(msg.sender, amountOfETH, amountOfTokens);
        
    }

    // lets the owner withdraw ETH
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is zero!");
        payable(msg.sender).transfer(balance);
    }

    function sellTokens(uint256 amount) external {
        uint256 balanceOf = yourToken.balanceOf(msg.sender);
        require(balanceOf > 0, "Balance is zero!");
        require(balanceOf >= amount, "Amount must be less than or equals to balance!");
        uint256 amountOfETH = amount / tokensPerEth;
        bool isTransferred = yourToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require (isTransferred, "Transfer of tokens failed!");
        payable(msg.sender).transfer(amountOfETH);
        emit SellTokens(msg.sender, amountOfETH, amount);
    }

    receive() external payable {
        buyTokens();
    }
}
