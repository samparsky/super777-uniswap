/* eslint-disable func-names */

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments;
  const deployer = await getNamedAccounts();
  const uniswapRouter = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';

  await deploy('UniswapSuperTokenToSuperTokenAdapter', {
    from: deployer,
    args: [uniswapRouter],
    log: true,
  });
};

module.exports.tags = ['UniswapSuperTokenToSuperTokenAdapter'];
