// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "./TestUniswapFactory.sol";
import "./WETH.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./UniswapV2Library.sol";
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

contract TestUniswapRouter is IUniswapV2Router02 {

  address public immutable weth;
  address public override factory;

  constructor(address _weth) {
    factory = address(new TestUniswapFactory());
    weth = _weth;
  }

  receive() external payable {}

  function WETH() external view returns (address) {
    return weth;
  }

  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
    _;
  }

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
      amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
      require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
      TransferHelper.safeTransferFrom(
          path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
      );
      _swap(amounts, path, to);
  }

  // **** SWAP ****
  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
      for (uint i; i < path.length - 1; i++) {
          (address input, address output) = (path[i], path[i + 1]);
          (address token0,) = UniswapV2Library.sortTokens(input, output);
          uint amountOut = amounts[i + 1];
          (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
          address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
          IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
              amount0Out, amount1Out, to, new bytes(0)
          );
      }
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
