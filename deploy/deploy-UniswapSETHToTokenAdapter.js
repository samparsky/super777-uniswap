/* eslint-disable no-console */
/* eslint-disable func-names */
const constants = require('../scripts/constants');

module.exports = async function ({ getNamedAccounts, deployments, network }) {
  const { deploy } = deployments;
  const deployer = await getNamedAccounts();
  const weth = process.env.WETH || constants.WETH[network.name];
  const router = process.env.ROUTER || constants.ROUTER[network.name];

  if (!weth) {
    console.log(`UniswapSETHToTokenAdapter: !! Please provide a valid WETH address for ${network.name} !! `);
    return;
  }

  if (!router) {
    console.log(`UniswapSETHToTokenAdapter: !! Please provide a valid Router address for ${network.name} !!`);
    return;
  }

  await deploy('UniswapSETHToTokenAdapter', {
    from: deployer,
    args: [router, weth],
    log: true,
  });
};

module.exports.tags = ['UniswapSETHToTokenAdapter'];
