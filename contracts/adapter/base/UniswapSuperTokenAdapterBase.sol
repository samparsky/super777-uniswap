// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../Receiver.sol";
import "../../interfaces/IUniswapV2Router02.sol";
import "../../interfaces/ISuperToken.sol";
import "../../interfaces/IUniswapV2Factory.sol";
import "../../interfaces/IUniswapV2Pair.sol";
import "hardhat/console.sol";


abstract contract UniswapSuperTokenAdapterBase is Receiver {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    IUniswapV2Router02 public immutable uniswapRouter;
    bytes32 public constant UUID = keccak256("org.superfluid-finance.contracts.SuperToken.implementation");

    event SwapComplete(
        address indexed from,
        address outputToken,
        uint256 amount
    );

    constructor(IUniswapV2Router02 _uniswapRouter) {
        uniswapRouter = _uniswapRouter;
    }

    /**
    *
    *
    * @notice 
        If DAIx is sent to this, it will downgrade it tofDAI
        interact with the DAI/USDC uniswap pool & it will swap to USDC
        upgrade USDC to USDCx then transfer USDCx to the `from` address
    * @param _token ERC777 token being transferred
    * @param from Address transferring the tokens
    * @param amount Amount being transferred
    * @param userData userData ABI encoded bytes value of (outputToken, minimumOutputAMount, trade deadline)
    */
    function _tokensReceived(
        IERC777 _token,
        address from,
        uint256 amount,
        bytes calldata userData
    ) internal override {
        address userSwapOutputToken;
        uint256 userMinSwapOutputAmount;
        uint256 userTradeDeadline; 
        (
            userSwapOutputToken,
            userMinSwapOutputAmount,
            userTradeDeadline
        ) = abi.decode(userData, (address, uint256, uint256));

        require(userSwapOutputToken != address(0), "invalid output token address");
        require(userMinSwapOutputAmount != 0, "invalid output amount");
        require(userTradeDeadline != 0, "invalid deadline");

        bool isUserSwapOutputTokenASuperToken = isSuperToken(ISuperToken(userSwapOutputToken));
        
        address to;
        ERC20 outputToken;
        
        if (isUserSwapOutputTokenASuperToken) {
            to = address(this);
            outputToken = ERC20(swapOutputUnderlying(ISuperToken(userSwapOutputToken)));
        } else {
            to = from;
            outputToken = ERC20(userSwapOutputToken);
        }
    
        ERC20 underlyingInputToken = ERC20(swapInputUnderlying(ISuperToken(address(_token))));

        // downgrade amount
        downgrade(ISuperToken(address(_token)), amount);
        
        address[] memory path = new address[](2);
        path[0] = address(underlyingInputToken);
        path[1] = address(outputToken);

        // approve the router to spend
        underlyingInputToken.safeIncreaseAllowance(address(uniswapRouter), amount);

        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amount,
            userMinSwapOutputAmount,
            path,
            to,
            userTradeDeadline
        );

        uint swapOutputAmount = amounts[1];

        if (isUserSwapOutputTokenASuperToken) {
            outputToken.safeIncreaseAllowance(userSwapOutputToken, swapOutputAmount);
            upgradeTo(ISuperToken(userSwapOutputToken), from, swapOutputAmount);
        }

        emit SwapComplete(from, userSwapOutputToken, swapOutputAmount);
    }

    /**
    * @param superToken the super token to upgrade to
    * @param to the address to send the upgraded tokens to
    * @param amount amount of tokens to upgrade to super tokens
     */
    function upgradeTo(ISuperToken superToken, address to, uint256 amount) internal virtual;

    /**
    * @param superToken the super token to downgrade from 
    * @param amount amount of tokens to downgrade
     */
    function downgrade(ISuperToken superToken, uint256 amount) internal virtual;

    /**
    * @param superToken the super token get underlying from
    */
    function swapInputUnderlying(ISuperToken superToken) internal view virtual returns(address);

    /**
    * @param superToken the super token get underlying from
    */
    function swapOutputUnderlying(ISuperToken superToken) internal view virtual returns(address);

    function isSuperToken(ISuperToken token) internal view returns (bool) {
        try token.proxiableUUID() returns (bytes32 _uuid) {
            return UUID == _uuid;
        } catch {
            return false;
        }
    }
}