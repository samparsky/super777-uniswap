// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../Receiver.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/ISuperToken.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";

contract UniswapSuperTokenToTokenAdapter is Receiver {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    bytes32 public constant UUID = keccak256("org.superfluid-finance.contracts.SuperToken.implementation");
    IUniswapV2Router02 public immutable uniswapRouter;

    event SwapComplete(
        address indexed from,
        address inputToken,
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
        If DAIx is sent with USDCx specified as output token,the contracts downgrades DAIx to DAI
        interacts with the DAI/USDC uniswap pair & swap DAI to USDC
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
            outputToken = ERC20(ISuperToken(userSwapOutputToken).getUnderlyingToken());
            require(address(outputToken) != address(0), "invalid underlying token");
        } else {
            to = from;
            outputToken = ERC20(userSwapOutputToken);
        }
        address inputAddress = address(_token);
        ERC20 underlyingInputToken = ERC20(ISuperToken(inputAddress).getUnderlyingToken());

        // downgrade amount
        ISuperToken(inputAddress).downgrade(amount);

        uint swapOutputAmount = swap(
            underlyingInputToken,
            address(outputToken),
            to,
            amount,
            userMinSwapOutputAmount,
            userTradeDeadline
        );

        if (isUserSwapOutputTokenASuperToken) {
            outputToken.safeIncreaseAllowance(userSwapOutputToken, swapOutputAmount);
            ISuperToken(userSwapOutputToken).upgradeTo(from, swapOutputAmount, "");
        }

        emit SwapComplete(
            from,
            inputAddress,
            userSwapOutputToken,
            swapOutputAmount
        );
    }

    function swap(
        ERC20 inputToken,
        address outputToken,
        address to,
        uint256 amount,
        uint256 minOutput,
        uint256 deadline
    ) internal returns(uint) {        
        address[] memory path = new address[](2);
        path[0] = address(inputToken);
        path[1] = outputToken;

        // approve the router to spend
        inputToken.safeIncreaseAllowance(address(uniswapRouter), amount);

        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amount,
            minOutput,
            path,
            to,
            deadline
        );

        return amounts[1];
    }

    function isSuperToken(ISuperToken token) internal view returns (bool) {
        try token.proxiableUUID() returns (bytes32 _uuid) {
            return UUID == _uuid;
        } catch {
            return false;
        }
    }
}