pragma solidity >=0.6.2 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

contract SuperToken is ERC20, ERC20Detailed {
    
    constructor(uint256 _initialSupply) ERC20Detailed("SuperTOken", "SPT", 18) public {
        _mint(account, amount);
    }

    function isSuperToken() external returns (bool) {
        return true;
    }
}