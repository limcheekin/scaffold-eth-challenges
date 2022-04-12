pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

// REF: https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90
contract DEX {
    IERC20 token;
    uint256 public totalLiquidity;
    uint8 public constant fee = 3; // 0.3%
    mapping(address => uint256) public liquidity;

    constructor(address token_address) {
        token = IERC20(token_address);
    }

    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX:init - already has liquidity");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens));
        return totalLiquidity;
    }

    function price(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public view returns (uint256) {
        console.log("input_amount:", input_amount);
        console.log("input_reserve:", input_reserve);
        console.log("output_reserve:", output_reserve);
        uint256 input_amount_with_fee = input_amount * (1000 - fee);
        uint256 numerator = input_amount_with_fee * output_reserve;
        uint256 denominator = input_reserve * 1000 + input_amount_with_fee;
        console.log("input_amount_with_fee:", input_amount_with_fee);
        console.log("numerator:", numerator);
        console.log("denominator:", denominator);
        return numerator / denominator;
    }

    function ethToToken() public payable returns (uint256) {
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_bought = price(
            msg.value,
            address(this).balance - msg.value,
            token_reserve
        );

        console.log("msg.value:", msg.value);
        console.log("address(this).balance:", address(this).balance);
        console.log("token_reserve:", token_reserve);
        console.log("tokens_bought:", tokens_bought);

        require(token.transfer(msg.sender, tokens_bought));
        return tokens_bought;
    }

    function tokenToEth(uint256 tokens) public returns (uint256) {
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_bought = price(
            tokens,
            token_reserve,
            address(this).balance
        );
        console.log("tokens:", tokens);
        console.log("address(this).balance:", address(this).balance);
        console.log("token_reserve:", token_reserve);
        console.log("eth_bought:", eth_bought);
        payable(msg.sender).transfer(eth_bought);
        require(token.transferFrom(msg.sender, address(this), tokens));
        return eth_bought;
    }

    /*
    The deposit() function receives ETH and also transfers tokens from the caller to the contract
    at the right ratio. The contract also tracks the amount of liquidity the depositing address 
    owns vs the totalLiquidity.
    */
    function deposit() public payable returns (uint256) {
        uint256 eth_reserve = address(this).balance - msg.value;
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 token_amount = (msg.value * token_reserve) / eth_reserve + 1;
        uint256 liquidity_minted = (msg.value * totalLiquidity) / eth_reserve;
        console.log("eth_reserve:", eth_reserve);
        console.log("token_reserve:", token_reserve);
        console.log("token_amount:", token_amount);
        console.log("liquidity_minted:", liquidity_minted);
        liquidity[msg.sender] = liquidity[msg.sender] + liquidity_minted;
        totalLiquidity = totalLiquidity + liquidity_minted;
        require(token.transferFrom(msg.sender, address(this), token_amount));
        return liquidity_minted;
    }

    /*
    The withdraw() function lets a user take both ETH and tokens out at the correct ratio. 
    The actual amount of ETH and tokens a liquidity provider withdraws will be higher than 
    what they deposited because of the 0.3% fees collected from each trade. 
    This incentivizes third parties to provide liquidity.
    */
    function withdraw(uint256 amount) public returns (uint256, uint256) {
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_amount = amount * address(this).balance / totalLiquidity;
        uint256 token_amount = amount * token_reserve / totalLiquidity;
        console.log("eth_amount:", eth_amount);
        console.log("token_reserve:", token_reserve);
        console.log("token_amount:", token_amount);
        console.log("totalLiquidity:", totalLiquidity);
        liquidity[msg.sender] = liquidity[msg.sender] - eth_amount;
        totalLiquidity = totalLiquidity - eth_amount;
        payable(msg.sender).transfer(eth_amount);
        require(token.transfer(msg.sender, token_amount));
        return (eth_amount, token_amount);
    }
}
