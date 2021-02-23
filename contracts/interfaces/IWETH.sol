// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.1;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function totalSupply() external view returns (uint);
}
