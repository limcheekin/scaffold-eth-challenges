pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// learn more:
// https://docs.openzeppelin.com/contracts/3.x/erc20
// https://docs.ethhub.io/guides/a-straightforward-guide-erc20-tokens/

contract Balloons is ERC20 {
    constructor() ERC20("Balloons", "BAL") {
        _mint(msg.sender, 1000 * 10**18);
    }
}
