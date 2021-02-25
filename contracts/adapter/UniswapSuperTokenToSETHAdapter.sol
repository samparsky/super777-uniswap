// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.1;

import "./base/UniswapSuperTokenAdapterBase.sol";

contract UniswapSuperTokenToSETHAdapter is UniswapSuperTokenAdapterBase {
    address public immutable WETH;

    constructor(IUniswapV2Router02 _uniswapRouter, address _weth) UniswapSuperTokenAdapterBase(_uniswapRouter) {
        WETH = _weth;
    }

    function upgradeTo(ISuperToken superToken, address /*to*/, uint256 amount) internal override {
        superToken.upgradeByWETH(amount);
    }

    function downgrade(ISuperToken superToken, uint256 amount) internal override {
        superToken.downgrade(amount);
    }

    function swapInputUnderlying(ISuperToken superToken) internal view override returns(address) {
        return superToken.getUnderlyingToken();
    }

    function swapOutputUnderlying(ISuperToken /*superToken*/) internal view override returns(address) {
        return WETH;
    }
}
