// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.1;

import "./base/UniswapSuperTokenAdapterBase.sol";

contract UniswapSuperTokenToTokenAdapter is UniswapSuperTokenAdapterBase {
    constructor(IUniswapV2Router02 _uniswapRouter) UniswapSuperTokenAdapterBase(_uniswapRouter) {}

    function upgradeTo(ISuperToken superToken, address to, uint256 amount) internal override {
        superToken.upgradeTo(to, amount, "");
    }

    function downgrade(ISuperToken superToken, uint256 amount) internal override {
        superToken.downgrade(amount);
    }

    function swapInputUnderlying(ISuperToken superToken) internal view override returns(address) {
        return superToken.getUnderlyingToken();
    }

    function swapOutputUnderlying(ISuperToken superToken) internal view override returns(address) {
        return superToken.getUnderlyingToken();
    }
}
