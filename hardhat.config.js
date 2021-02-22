/* eslint-disable no-restricted-syntax */
/* eslint-disable no-undef */
/* eslint-disable import/no-extraneous-dependencies */
require('@nomiclabs/hardhat-truffle5');
require('hardhat-deploy');
// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  networks: {
    hardhat: {},
    // local: {
    //   url: 'http://localhost:8545',
    // },
    // kovan: {
    //   url: `https://kovan.infura.io/v3/${process.env.INFURA_KEY}`,
    //   accounts: {
    //     mnemonic: process.env.MNEMONIC,
    //   },
    //   gasPrice: 1000000000,
    // },
    // rinkeby: {
    //   url: `https://rinkeby.infura.io/v3/${process.env.INFURA_KEY}`,
    //   accounts: {
    //     mnemonic: process.env.MNEMONIC,
    //   },
    //   gasPrice: 1000000000,
    // },
    // mainnet: {
    //   // url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
    //   accounts: {
    //     // mnemonic: process.env.MNEMONIC,
    //   },
    // },
  },

  solidity: {
    version: '0.7.4',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },

  namedAccounts: {
    deployer: {
      default: 0,
    },
  },

};
