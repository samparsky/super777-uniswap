// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.1;

interface ISuperToken {
    function upgradeTo(address to, uint256 amount, bytes calldata data) external;
    function upgrade(uint256 amount) external;
    function downgrade(uint256 amount) external;
    function getUnderlyingToken() external view returns (address tokenAddr);
    function proxiableUUID() external view returns(bytes32);
    function balanceOf(address account) external view returns(uint256 balance);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function downgradeToWETH(uint wad) external;
    function upgradeByWETH(uint wad) external payable;
}
