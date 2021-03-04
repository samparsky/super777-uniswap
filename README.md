# Super777 Uniswap

Integrates Uniswap with Super777 tokens

# How it works

We make use of the `tokensReceived` hook defined in ERC777.

You send a Super777 token to an ens or ethereum address e.g. super777.swap.eth with an encoded data that contains (output token, expected amount, trade deadline) and then the contract swaps the Super777 token to the output token and forwards the output token to the sender address. It allows receiving both super or non-super tokens.

The address supports any token as long as it has a listed pair on uniswap. The contracts are meant to be used with a flow/UI that encodes the required swap data to be provided as part of the transaction.

#### Example

- A user wants to swap SETH (Super777 Ethereum) to USDCx (Super777 USDC). They send SETH to an ens or ethereum address e.g. seth.swap.super777.eth, the swaps the underlying ETH to USDC 
via Uniswap, wraps the received USDC to USDCx and transfers it to the user all in one transaction.

- A user wants to swap USDCx (Super USDC) to DAIx (Super DAI). They send USDCx to an ethereum address e.g. swap.super777.eth, this swaps the underlying USDC to DAI via Uniswap and wraps
the received DAI to DAIx then transfers it to the user all in one transaction

# Deployment

```sh
$ export ROUTER=
$ npx hardhat --network [goerli|ropsten] deploy

```


# LICENSE

MIT