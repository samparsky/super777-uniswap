// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function totalSupply() external view returns (uint);
}
