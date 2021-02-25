/* eslint-disable func-names */
const constants = require('../scripts/constants');

module.exports = async function ({ getNamedAccounts, deployments, network }) {
  const { deploy } = deployments;
  const deployer = await getNamedAccounts();
  const weth = constants.WETH[network];

  await deploy('UniswapSETHToSuperTokenAdapter', {
    from: deployer,
    args: [constants.UNISWAP_ROUTER, weth],
    log: true,
  });
};

module.exports.tags = ['UniswapSETHToSuperTokenAdapter'];
