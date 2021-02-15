// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

interface ISuperToken {
    function upgradeTo(address to, uint256 amount, bytes calldata data) external;
    function downgrade(uint256 amount) external;
    function getUnderlyingToken() external view returns (address tokenAddr);
    function proxiableUUID() external view returns(bytes32);
}