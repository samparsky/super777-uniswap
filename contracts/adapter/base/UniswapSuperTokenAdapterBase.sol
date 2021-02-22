// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../ens/ReverseENS.sol";
import "../../Receiver.sol";
import "../../interfaces/IUniswapV2Router02.sol";
import "../../interfaces/ISuperToken.sol";
import "../../interfaces/IUniswapV2Factory.sol";
import "../../interfaces/IUniswapV2Pair.sol";
import "hardhat/console.sol";


abstract contract UniswapSuperTokenAdapterBase is Receiver, ReverseENS {
    using SafeMath for uint256;

    IUniswapV2Factory public immutable uniswapFactory;
    bytes32 constant UUID = keccak256("org.superfluid-finance.contracts.SuperToken.implementation");

    constructor(IUniswapV2Router02 _uniswapRouter) {
        uniswapFactory = _uniswapRouter.factory();
    }

    /**
    *
    *
    Example: Assume this is a fUSDC output Uniswap contract
        If fDAIx is sent to this, it will downgrade it to fDAI
        interact with the fDAI/fUSDC uniswap pool & it will swap to fUSDC
        upgrade fUSDC to fUSDx then transfer fUSDCx to the `from` address
    */
    function _tokensReceived(
        IERC777 _token,
        address from,
        uint256 amount,
        bytes calldata data
    ) internal override {
        address userSwapOutputToken;
        uint256 userMinSwapOutputAmount;
        uint256 userTradeDeadline; 
        (
            userSwapOutputToken,
            userMinSwapOutputAmount,
            userTradeDeadline
        ) = abi.decode(data, (address, uint256, uint256));

        require(userSwapOutputToken != address(0), "invalid output token address");
        require(userMinSwapOutputAmount != 0, "invalid output amount");
        require(userTradeDeadline != 0 && block.timestamp <= userTradeDeadline, "invalid deadline");

        bool isUserSwapOutputTokenASuperToken = isSuperToken(ISuperToken(userSwapOutputToken));
        
        address to;
        ERC20 outputToken;
        
        if (isUserSwapOutputTokenASuperToken) {
            to = address(this);
            outputToken = ERC20(ISuperToken(userSwapOutputToken).getUnderlyingToken());
        } else {
            to = from;
            outputToken = ERC20(userSwapOutputToken);
        }

        ISuperToken inputSuperToken = ISuperToken(address(_token));
        ERC20 underlyingInputToken = ERC20(inputSuperToken.getUnderlyingToken());

        // downgrade amount
        downgrade(inputSuperToken, amount);

        uint swapOutputAmount = executeSwap(
            address(underlyingInputToken),
            address(outputToken),
            amount,
            userMinSwapOutputAmount,
            to
        );

        require(swapOutputAmount > 0, "NO_PAIR");

        if (isUserSwapOutputTokenASuperToken) {
            outputToken.approve(userSwapOutputToken, swapOutputAmount);
            upgradeTo(ISuperToken(userSwapOutputToken), from, swapOutputAmount);
        }
    }

    function executeSwap(
        address input,
        address out,
        uint256 swapAmount,
        uint256 minSwapOutputAmount,
        address to
    ) internal returns (uint256 outputAmount) {
        IUniswapV2Pair pair =
            IUniswapV2Pair(uniswapFactory.getPair(input, out));

        if (address(pair) == address(0)) {
            return 0;
        }

        address token0 = address(pair.token0());

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveIn, uint256 reserveOut) =
            input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

        outputAmount = getAmountOut(
            swapAmount,
            reserveIn,
            reserveOut
        );

        require(outputAmount >= minSwapOutputAmount, "INSUFFICIENT_OUTPUT_AMOUNT");

        if (swapAmount > 0) {
            TransferHelper.safeTransfer(input, address(pair), swapAmount);
        }

        (uint256 amount0Out, uint256 amount1Out) =
            input == token0
                ? (uint256(0), outputAmount)
                : (outputAmount, uint256(0));

        pair.swap(amount0Out, amount1Out, to, "");
    }

    function upgradeTo(ISuperToken superToken, address to, uint256 amount) internal virtual;
    function downgrade(ISuperToken superToken, uint256 amount) internal virtual;
    // function getUnderlyingToken(ISuperToken superToken) internal virtual returns(address);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function isSuperToken(ISuperToken token) internal view returns (bool) {
        try token.proxiableUUID() returns (bytes32 _uuid) {
            return UUID == _uuid;
        } catch {
            return false;
        }
    }
}