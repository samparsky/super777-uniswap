// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20("Mock USDC", "mUSDC") {
    constructor ()  {
        _mint(msg.sender, 10000 ether);
    }
}
