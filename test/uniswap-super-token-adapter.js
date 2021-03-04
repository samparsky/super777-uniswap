/* global describe,it,web3,before,beforeEach */

const { singletons, expectEvent } = require('@openzeppelin/test-helpers');
const SuperfluidSDK = require('@superfluid-finance/js-sdk');
const deployTestToken = require('@superfluid-finance/ethereum-contracts/scripts/deploy-test-token');
const deploySuperToken = require('@superfluid-finance/ethereum-contracts/scripts/deploy-super-token');
const deployFramework = require('@superfluid-finance/ethereum-contracts/scripts/deploy-framework');

const { assert, artifacts } = require('hardhat');

const eth = (num) => web3.utils.toWei(num.toString(), 'ether');
const IUniswapV2Factory = artifacts.require('IUniswapV2Factory');
const TestUniswapPair = artifacts.require('TestUniswapPair');
const TestUniswapRouter = artifacts.require('TestUniswapRouter');
const UniswapSuperTokenAdapter = artifacts.require('UniswapSuperTokenToTokenAdapter');

const WETH = artifacts.require('WETH');

const { toBN } = web3.utils;

const errorHandler = (err) => {
  if (err) throw err;
};

async function expectEVMError(promise, errString) {
  try {
    await promise;
    assert.isOk(false, `should have failed with ${errString}`);
  } catch (e) {
    const expectedString = errString
      ? `VM Exception while processing transaction: revert ${errString}`
      : 'VM Exception while processing transaction: revert';
    assert.equal(e.message, expectedString, 'error message is incorrect');
  }
}

describe('UniswapSuperTokenAdapter', () => {
  let accounts;
  let defaultSender;

  let superFluidFramework;
  let fUsdc;
  let fDai;
  let fUsdcX; // super usdc
  let fDaiX; // super dai
  let fETHx; // super eth
  let weth;

  async function setupUniswap(token1, token2) {
    const uniswapRouter = await TestUniswapRouter.new(weth.address);

    if (token2.address === weth.address) {
      // eslint-disable-next-line no-param-reassign
      token2 = await WETH.at(await uniswapRouter.weth());
      await token2.deposit({ value: eth(1000) });
    }

    const uniswapFactory = await IUniswapV2Factory.at(await uniswapRouter.factory());
    await uniswapFactory.createPair(token1.address, token2.address);
    const pair = await TestUniswapPair.at(
      await uniswapFactory.getPair(token1.address, token2.address),
    );

    await Promise.all([
      token1.transfer(pair.address, eth(1000)),
      token2.transfer(pair.address, eth(1000)),
    ]);
    await pair.mint('0x0000000000000000000000000000000000000001');

    return { uniswapRouter, uniswapFactory, pair };
  }

  before(async () => {
    accounts = await web3.eth.getAccounts();
    ([defaultSender] = accounts);

    await singletons.ERC1820Registry(defaultSender);

    await deployFramework(errorHandler, {
      web3,
      nonUpgradable: true,
    });

    weth = await WETH.new();
  });

  beforeEach(async () => {
    await deploySuperToken(errorHandler, [':', 'ETH'], {
      web3,
      weth: weth.address,
    });

    await deployTestToken(errorHandler, [':', 'fDAI'], {
      web3,
    });

    await deployTestToken(errorHandler, [':', 'fUSDC'], {
      web3,
    });

    await deploySuperToken(errorHandler, [':', 'fDAI'], {
      web3,
    });

    await deploySuperToken(errorHandler, [':', 'fUSDC'], {
      web3,
    });

    superFluidFramework = new SuperfluidSDK.Framework({
      web3,
      version: 'test',
      tokens: ['fDAI', 'fUSDC'],
    });

    await superFluidFramework.initialize();

    const fDaiAddress = await superFluidFramework.tokens.fDAI.address;
    const fUSDCAddress = await superFluidFramework.tokens.fUSDC.address;

    fDai = await superFluidFramework.contracts.TestToken.at(fDaiAddress);
    fUsdc = await superFluidFramework.contracts.TestToken.at(fUSDCAddress);

    // defaultSender
    await fDai.mint(defaultSender, eth(100000));
    await fUsdc.mint(defaultSender, eth(100000));

    fDaiX = superFluidFramework.tokens.fDAIx;
    fUsdcX = superFluidFramework.tokens.fUSDCx;

    const fETHxAddress = await superFluidFramework.resolver.get('supertokens.test.ETHx');
    fETHx = await superFluidFramework.contracts.ISETH.at(fETHxAddress);
  });

  it('Should fail with invalid userData', async () => {
    const { uniswapRouter } = await setupUniswap(fDai, fUsdc);
    const uniswapSuperTokenAdapter = await UniswapSuperTokenAdapter.new(uniswapRouter.address);
    await fUsdc.approve(fUsdcX.address, eth(100));
    await fUsdcX.upgrade(eth(100)); // mint super fUSDC to defaultSender

    // encode calldata
    const userdata = web3.eth.abi.encodeParameters(
      ['uint256', 'uint256', 'uint256'],
      ['0x0', `${eth(9)}`, `${Math.floor(Date.now() / 1000) + 36000}`],
    );

    // transfer & swap with uniswapSuperTokenAdapter
    await expectEVMError(
      fUsdcX.send(uniswapSuperTokenAdapter.address, eth(10), userdata),
      'invalid output token address',
    );
  });

  it('Should swap superToken for superToken', async () => {
    const { uniswapRouter } = await setupUniswap(fDai, fUsdc);
    const uniswapSuperTokenAdapter = await UniswapSuperTokenAdapter.new(uniswapRouter.address);
    await fUsdc.approve(fUsdcX.address, eth(100));
    await fUsdcX.upgrade(eth(100)); // mint super fUSDC to defaultSender

    // encode calldata
    const userdata = web3.eth.abi.encodeParameters(
      ['address', 'uint256', 'uint256'],
      [`${fDaiX.address}`, `${eth(9)}`, `${Math.floor(Date.now() / 1000) + 36000}`],
    );

    const beforeBalance = ((await fDaiX.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();
    // transfer & swap with uniswapSuperTokenAdapter
    const tx = await fUsdcX.send(uniswapSuperTokenAdapter.address, eth(10), userdata);
    await expectEvent.inTransaction(tx.tx, UniswapSuperTokenAdapter, 'SwapComplete');

    // check balance after
    const afterBalance = ((await fDaiX.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();
    const swapOutputAmount = 9;
    assert.equal((beforeBalance + swapOutputAmount), afterBalance, 'invalid swap');
  });

  it('Should swap superToken for token', async () => {
    const { uniswapRouter } = await setupUniswap(fDai, fUsdc);

    const uniswapSuperTokenAdapter = await UniswapSuperTokenAdapter.new(uniswapRouter.address);
    const userdata = web3.eth.abi.encodeParameters(
      ['address', 'uint256', 'uint256'],
      [`${fDai.address}`, `${eth(9)}`, `${Math.floor(Date.now() / 1000) + 36000}`],
    );

    const beforeBalance = ((await fDai.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();
    await fUsdc.approve(fUsdcX.address, eth(100));
    await fUsdcX.upgrade(eth(100));
    // transfer to uniswapSuperTokenAdapter
    const tx = await fUsdcX.send(uniswapSuperTokenAdapter.address, eth(10), userdata);
    await expectEvent.inTransaction(tx.tx, UniswapSuperTokenAdapter, 'SwapComplete');

    const afterBalance = ((await fDai.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();
    const swapOutputAmount = 9;
    assert.equal((beforeBalance + swapOutputAmount), afterBalance, 'invalid swap');
  });

  it('Should swap superToken for SETH', async () => {
    const { uniswapRouter } = await setupUniswap(fUsdc, weth);
    const uniswapSuperTokenAdapter = await UniswapSuperTokenAdapter.new(
      uniswapRouter.address,
    );
    const userdata = web3.eth.abi.encodeParameters(
      ['address', 'uint256', 'uint256'],
      [`${fETHx.address}`, `${eth(9)}`, `${Math.floor(Date.now() / 1000) + 36000}`],
    );

    const beforeBalance = ((await fETHx.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();

    // transfer & swap with uniswapSuperTokenAdapter
    await fUsdc.approve(fUsdcX.address, eth(100));
    await fUsdcX.upgrade(eth(100));
    const tx = await fUsdcX.send(uniswapSuperTokenAdapter.address, eth(10), userdata);
    await expectEvent.inTransaction(tx.tx, UniswapSuperTokenAdapter, 'SwapComplete');

    const swapOutputAmount = 9;
    const afterBalance = ((await fETHx.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();
    assert.equal((beforeBalance + swapOutputAmount), afterBalance, 'invalid swap');
  });

  it('Should swap SETH for superToken', async () => {
    const { uniswapRouter } = await setupUniswap(fUsdc, weth);
    const uniswapSuperTokenAdapter = await UniswapSuperTokenAdapter.new(
      uniswapRouter.address,
    );
    const userdata = web3.eth.abi.encodeParameters(
      ['address', 'uint256', 'uint256'],
      [`${fUsdcX.address}`, `${eth(9)}`, `${Math.floor(Date.now() / 1000) + 36000}`],
    );

    const beforeBalance = ((await fUsdcX.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();

    await fETHx.upgradeByETH({ value: eth(100) });

    const tx = await fETHx.send(uniswapSuperTokenAdapter.address, eth(10), userdata);
    await expectEvent.inTransaction(tx.tx, UniswapSuperTokenAdapter, 'SwapComplete');

    const swapOutputAmount = 9;

    const afterBalance = ((await fUsdcX.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();
    assert.equal((beforeBalance + swapOutputAmount), afterBalance, 'invalid swap');
  });

  it('Should swap SETH for token', async () => {
    const { uniswapRouter } = await setupUniswap(fUsdc, weth);
    const uniswapSuperTokenAdapter = await UniswapSuperTokenAdapter.new(
      uniswapRouter.address,
    );
    const userdata = web3.eth.abi.encodeParameters(
      ['address', 'uint256', 'uint256'],
      [`${fUsdc.address}`, `${eth(9)}`, `${Math.floor(Date.now() / 1000) + 36000}`],
    );

    const beforeBalance = ((await fUsdc.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();

    await fETHx.upgradeByETH({ value: eth(100) });
    // send it to uniswapSuperTokenAdapter
    const tx = await fETHx.send(uniswapSuperTokenAdapter.address, eth(10), userdata);
    await expectEvent.inTransaction(tx.tx, UniswapSuperTokenAdapter, 'SwapComplete');

    const afterBalance = ((await fUsdc.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();
    const swapOutputAmount = 9;
    assert.equal((beforeBalance + swapOutputAmount), afterBalance, 'invalid swap');
  });
});
