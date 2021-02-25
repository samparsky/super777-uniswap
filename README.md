# Super777 Uniswap

Integrates Uniswap with Super777 tokens

# How it works

You send a Super777 token to an ens address e.g. super777.swap.eth with an encoded data that contains (output token, expected amount, trade deadline) and the contract automatically performs the swap and sends the output token to your address. It allows receiving both super or non-super tokens.

The contracts are meant to be used with a flow/UI that encodes the required swap data to be provided as part of the transaction.

# LICENSE

MIT