// SPDX-License-Identifier: GNU
pragma solidity >=0.6.2;

import './IUniswapV2Factory.sol';

interface IUniswapV2Router01 /*is IUniswapV2Library*/ {
    function WETH() external view returns (address);
    function factory() external view returns (IUniswapV2Factory);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}