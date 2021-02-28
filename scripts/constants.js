const UNISWAP_ROUTER = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const HONEYSWAP_ROUTER = '0x1C232F01118CB8B424793ae03F870aa7D0ac7f77';

const Addresses = {
  WETH: {
    mainnet: '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
  },
  ROUTER: {
    rinkeby: UNISWAP_ROUTER,
    ropsten: UNISWAP_ROUTER,
    goerli: UNISWAP_ROUTER,
    kovan: UNISWAP_ROUTER,
    xdai: HONEYSWAP_ROUTER,
    mainnet: UNISWAP_ROUTER,
  },
};

module.exports = Addresses;
