/* eslint-disable no-console */
/* eslint-disable func-names */
const constants = require('../scripts/constants');

module.exports = async function ({ getNamedAccounts, deployments, network }) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const router = process.env.ROUTER || constants.ROUTER[network];
  if (!router) {
    console.log(`UniswapSuperTokenToTokenAdapter: !! Please provide a valid Router address for ${network.name} !!`);
    return;
  }

  await deploy('UniswapSuperTokenToTokenAdapter', {
    from: deployer,
    args: [router],
    log: true,
  });
};

module.exports.tags = ['UniswapSuperTokenToTokenAdapter'];
