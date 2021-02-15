// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "../../../ens/ReverseENS.sol";
import "../../../Receiver.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router01.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/ISuperToken.sol";

contract UniswapSuperTokenAdapter is Receiver, ReverseENS {
    using SafeMath for uint256;

    IUniswapV2Factory public immutable uniswapFactory;
    bytes32 constant UUID = keccak256("org.superfluid-finance.contracts.SuperToken.implementation");

    constructor(IUniswapV2Router01 _uniswapRouter) public {
        uniswapFactory = _uniswapRouter.factory();
    }

    /**
     * Ex: Assume this is a fUSDC output Uniswap contract
     * If fDAIx is sent to this, it will downgrade it to fDAI
     * interact with the fDAI/fUSDC uniswap pool & it will swap to fUSDC
     * upgrade fUSDC to fUSDx then transfer fUSDCx to the `from` address
     */

    /**
    calldata encoding
        - payment 
        - output token
        - amount
        - 
     */

    function _tokensReceived(
        IERC777 _token,
        address from,
        uint256 amount,
        bytes calldata data
    ) internal override {
        /**
        swapOutputTokenAddress
         */
        // super token & eth swap
        // bool
        (address _outputToken, uint256 amount, uint256 tradeDeadline) = abi.decode(data, (address, uint256, uint256));
        bool isSuperToken = isSuperToken(ISuperToken(_outputToken));
        
        address swapOutputAddress;
        ERC20 outputToken;
        
        if (isSuperToken) {
            swapOutputAddress = address(this);
            outputToken = ERC20(ISuperToken(_outputToken).getUnderlyingToken());
        } else {
            swapOutputAddress = from;
            outputToken = ERC20(_outputToken); 
        }
        // determine if the output token is a super token
        // and
        // outputToken = _outputToken;
        // outputUnderlyingToken = ERC20(_outputToken.getUnderlyingToken());
        ISuperToken inputSuperToken = ISuperToken(address(_token));
        ERC20 unwrappedInput = ERC20(inputSuperToken.getUnderlyingToken());
        
        inputSuperToken.downgrade(amount);

        uint256 outputAmount = executeSwap(
                uniswapFactory,
                address(unwrappedInput),
                address(outputToken),
                amount,
                swapOutputAddress
            );
            
        require(outputAmount > 0, "NO_PAIR");
        // contract approve 
        if (isSuperToken) {
            outputToken.approve(address(outputToken), outputAmount);
            outputToken.upgradeTo(from, outputAmount, "");
        }
    }

    function getSwapTokenAddress(address outputToken) internal view returns (address, address) {
        address swapOutputAddress = from;
        if (isSuperToken) {
            swapOutputAddress = address(this);
        }
    }

    function executeSwap(
        IUniswapV2Factory uniswapFactory,
        address input,
        address out,
        uint256 swapAmount,
        address to
    ) internal returns (uint256 outputAmount) {
        IUniswapV2Pair pair =
            IUniswapV2Pair(uniswapFactory.getPair(input, out));

        if (address(pair) == address(0)) {
            return 0;
        }

        if (swapAmount > 0) {
            TransferHelper.safeTransfer(input, address(pair), swapAmount);
        }

        address token0 = address(pair.token0());

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveIn, uint256 reserveOut) =
            input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

        outputAmount = UniswapLibrary.getAmountOut(
            swapAmount,
            reserveIn,
            reserveOut
        );
        (uint256 amount0Out, uint256 amount1Out) =
            input == token0
                ? (uint256(0), outputAmount)
                : (outputAmount, uint256(0));

        pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }

    function isSuperToken(ISuperToken token) internal view returns (bool) {
        try token.proxiableUUID() returns (bytes32 _uuid) {
            return UUID == _uuid;
        } catch {
            return false;
        }
    }
}