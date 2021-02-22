// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "./TestUniswapFactory.sol";
import "./WETH.sol";

contract TestUniswapRouter is IUniswapV2Router02 {

  address public immutable weth;

  IUniswapV2Factory public _factory;

  constructor() {
    _factory = IUniswapV2Factory(new TestUniswapFactory());
    weth = address(new WETH());
  }

  receive() external payable {}

  function WETH() external view returns (address) {
    return weth;
  }

  function factory() external override view returns (IUniswapV2Factory) {
    return _factory;
  }


  function swapExactTokensForTokens(
      uint amountIn,
      uint /*amountOutMin*/,
      address[] calldata path,
      address to,
      uint /*deadline*/
  ) external override returns (uint[] memory amounts) {
    IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
    IERC20(path[path.length - 1]).transfer(to, amountIn);

    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    amounts[amounts.length - 1] = amountIn;
  }

  function swapExactETHForTokens(uint /*amountOutMin*/, address[] calldata path, address to, uint /*deadline*/)
    external override
    payable
    returns (uint[] memory amounts)
  {
    IERC20(path[path.length - 1]).transfer(to, msg.value);

    amounts = new uint[](path.length);
    amounts[0] = msg.value;
    amounts[amounts.length - 1] = msg.value;
  }

  function swapExactTokensForETH(uint amountIn, uint /*amountOutMin*/, address[] calldata path, address to, uint /*deadline*/)
    external override
    returns (uint[] memory amounts)
  {
    IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
    payable(to).transfer(amountIn);

    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    amounts[amounts.length - 1] = amountIn;
  }
}
