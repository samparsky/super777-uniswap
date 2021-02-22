const { singletons } = require('@openzeppelin/test-helpers');
const SuperfluidSDK = require('@superfluid-finance/js-sdk');
const deployTestToken = require('@superfluid-finance/ethereum-contracts/scripts/deploy-test-token');
const deploySuperToken = require('@superfluid-finance/ethereum-contracts/scripts/deploy-super-token');
const deployFramework = require('@superfluid-finance/ethereum-contracts/scripts/deploy-framework');

const { expect } = require('chai');
const abi = require('ethereumjs-abi');
const { assert } = require('hardhat');

const eth = (num) => web3.utils.toWei(num.toString(), 'ether');
const IUniswapV2Factory = artifacts.require('IUniswapV2Factory');
const TestUniswapPair = artifacts.require('TestUniswapPair');
const MockERC20 = artifacts.require('MockToken');
const TestUniswapRouter = artifacts.require('TestUniswapRouter');
const UniswapSuperTokenAdapter = artifacts.require('UniswapSuperTokenToSuperTokenAdapter');

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
  let fETH;
  let fUsdcX; // super usdc
  let fDaiX; // super dai
  let fETHx; // super eth

  async function setupUniswap(token1, token2) {
    const uniswapRouter = await TestUniswapRouter.new();

    // let token1Amt = '1';
    // let token2Amt = '1'

    // if (!token2) {
    //   token2 = await IWETH.at(await uniswapRouter.WETH());
    //   await token2.deposit({ value: eth(1) });
    //   token2Amt = '1';
    // }

    const uniswapFactory = await IUniswapV2Factory.at(await uniswapRouter.factory());
    await uniswapFactory.createPair(token1.address, token2.address);
    const pair = await TestUniswapPair.at(
      await uniswapFactory.getPair(token1.address, token2.address),
    );

    await Promise.all([
      token1.transfer(pair.address, eth(1000)),
      token2.transfer(pair.address, eth(1000)),
    ]);
    // console.log('token0  ', await pair.token0());
    // console.log('token1  ', await pair.token1());
    // console.log('balanceOf', (await token2.balanceOf(pair.address)).toString());
    // console.log('balanceOf', (await token1.balanceOf(pair.address)).toString());
    await pair.mint('0x0000000000000000000000000000000000000001');

    return { uniswapRouter, uniswapFactory, pair };
  }

  before(async () => {
    accounts = await web3.eth.getAccounts();
    ([defaultSender] = accounts);

    // console.log('default ', web3.eth.defaultAccount);
    // console.log(await (await web3.eth.getBalance(defaultSender)).toString());

    await singletons.ERC1820Registry(defaultSender);

    await deployFramework(errorHandler, {
      web3,
      // from: defaultSender,
      nonUpgradable: true,
    });
  });

  beforeEach(async () => {
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

    await deploySuperToken(errorHandler, [':', 'ETH'], {
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
    // console.log({ fDaiAddress });
    // console.log({ fUSDCAddress });

    fDai = await superFluidFramework.contracts.TestToken.at(fDaiAddress);
    fUsdc = await superFluidFramework.contracts.TestToken.at(fUSDCAddress);

    // defaultSender
    await fDai.mint(defaultSender, eth(100000));
    await fUsdc.mint(defaultSender, eth(100000));

    fDaiX = superFluidFramework.tokens.fDAIx;
    fUsdcX = superFluidFramework.tokens.fUSDCx;
    fETHx = superFluidFramework.tokens.ETHx;
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

  it('Should fail with invalid uniswap pair', async () => {
    const mockToken = await MockERC20.new();
    const { uniswapRouter } = await setupUniswap(fDai, fUsdc);
    const uniswapSuperTokenAdapter = await UniswapSuperTokenAdapter.new(uniswapRouter.address);
    await fUsdc.approve(fUsdcX.address, eth(100));
    await fUsdcX.upgrade(eth(100)); // mint super fUSDC to defaultSender

    // encode calldata
    const userdata = web3.eth.abi.encodeParameters(
      ['uint256', 'uint256', 'uint256'],
      [`${mockToken.address}`, `${eth(9)}`, `${Math.floor(Date.now() / 1000) + 36000}`],
    );

    // transfer & swap with uniswapSuperTokenAdapter
    await expectEVMError(
      fUsdcX.send(uniswapSuperTokenAdapter.address, eth(10), userdata),
      'NO_PAIR',
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
    await fUsdcX.send(uniswapSuperTokenAdapter.address, eth(10), userdata);
    // check balance after
    const afterBalance = ((await fDaiX.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();

    const swapOutputAmount = 9;
    assert.equal((beforeBalance + swapOutputAmount), afterBalance, 'invalid swap');
  });

  it('Should swap superToken for token', async () => {
    const { uniswapFactory, uniswapRouter, pair } = await setupUniswap(fDai, fUsdc);

    const uniswapSuperTokenAdapter = await UniswapSuperTokenAdapter.new(uniswapRouter.address);
    // encode calldata
    // console.log('fDaiX ', fDaiX.address);
    const userdata = web3.eth.abi.encodeParameters(
      ['address', 'uint256', 'uint256'],
      [`${fDai.address}`, `${eth(9)}`, `${Math.floor(Date.now() / 1000) + 36000}`],
    );

    const beforeBalance = ((await fDai.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();
    // console.log({ beforeBalance });
    await fUsdc.approve(fUsdcX.address, eth(100));
    await fUsdcX.upgrade(eth(100));
    // transfer to uniswapSuperTokenAdapter
    await fUsdcX.send(uniswapSuperTokenAdapter.address, eth(10), userdata);

    const afterBalance = ((await fDai.balanceOf(defaultSender)).div(toBN(eth(1)))).toNumber();
    // console.log({ afterBalance });
    const swapOutputAmount = 9;
    assert.equal((beforeBalance + swapOutputAmount), afterBalance, 'invalid swap');
  });

  it('Should swap superToken for SETH', async () => {
    const { uniswapRouter } = await setupUniswap(fDai, fUsdc)
    
  });

});
