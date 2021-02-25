/* eslint-disable func-names */
const constants = require('../scripts/constants');

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments;
  const deployer = await getNamedAccounts();

  await deploy('UniswapSuperTokenToSuperTokenAdapter', {
    from: deployer,
    args: [constants.UNISWAP_ROUTER],
    log: true,
  });
};

module.exports.tags = ['UniswapSuperTokenToSuperTokenAdapter'];
