var CoinsOpenToken = artifacts.require("./CoinsOpenToken.sol");

var BigNumber = require('bignumber.js');
require('babel-polyfill');

contract('CoinsOpenToken', function(accounts) {


  function sleep(delay) {
    var start = new Date().getTime();
    while (new Date().getTime() < start + delay);
  }

  function fromBigNumberWeiToEth(bigNum) {
    return bigNum.dividedBy(new BigNumber(10).pow(18)).toNumber();
  }

  async function addSeconds(seconds) {
    return web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [seconds], id: 0});
  }

  async function getTimestampOfCurrentBlock() {
    return web3.eth.getBlock(web3.eth.blockNumber).timestamp;
  }

  const gasAmount = 4612386;

  const owner = accounts[0];
  const buyer1 = accounts[1];
  const buyer2 = accounts[2];

  it("Presale is properly working", async () =>  {

    const COT = await CoinsOpenToken.new({from: owner, gas: gasAmount});

    // We jump to the presale opening
    const startsAt = await COT.preSaleStartTime.call();
    const currentBlockTimestamp = await getTimestampOfCurrentBlock();
    await addSeconds(startsAt - currentBlockTimestamp);

    const startingSupply = await COT.presaleSupply.call();

    weiRaised = await COT.totalWeiRaised.call();
    assert.equal(weiRaised.toNumber(), 0, "The amount of wei raised should be 0 at initialization.");

    const tokenPrice = await COT.preSaleTokenPrice.call();

    await COT.buyTokens(buyer1, {from: buyer1, gas: gasAmount, value: web3.toWei("1", "Ether")});

    const nbTokens = await COT.balanceOf(buyer1, {from: buyer1, gas: gasAmount});

    assert.closeTo(nbTokens.toNumber() / 1000000000000000000, web3.toWei("1", "Ether") * tokenPrice / 100 / 1000000000000000000, 0.0000001, "The amount of token bought is not correct.");

    weiRaised = await COT.totalWeiRaised.call();
    assert.equal(weiRaised.toNumber(), web3.toWei("1", "Ether"), "The amount of wei raised should be 1 Ethereum.");

    const endSupply = await COT.presaleSupply.call();

    assert.closeTo(endSupply.toNumber() + nbTokens.toNumber(), startingSupply.toNumber(), 1000000000000000000 , "The sale supply has not been correctly updated.");


  });


  it("Sale is properly working", async () =>  {

    const COT = await CoinsOpenToken.new({from: owner, gas: gasAmount});

    // We jump to the Sale opening
    const startsAt = await COT.saleStartTime.call();
    const currentBlockTimestamp = await getTimestampOfCurrentBlock();
    await addSeconds(startsAt - currentBlockTimestamp + 1000);

    const startingSupply = await COT.saleSupply.call();
    const prestartingSupply = await COT.presaleSupply.call();

    weiRaised = await COT.totalWeiRaised.call();
    assert.equal(weiRaised.toNumber(), 0, "The amount of wei raised should be 0 at initialization.");

    const tokenPrice = await COT.saleTokenPrice.call();

    await COT.buyTokens(buyer1, {from: buyer1, gas: gasAmount, value: web3.toWei("1", "Ether")});

    const nbTokens = await COT.balanceOf(buyer1, {from: buyer1, gas: gasAmount});


    assert.closeTo(nbTokens.toNumber() / 1000000000000000000, web3.toWei("1", "Ether") * tokenPrice / 100 / 1000000000000000000, 0.000001, "The amount of token bought is not correct.");

    weiRaised = await COT.totalWeiRaised.call();
    assert.equal(weiRaised.toNumber(), web3.toWei("1", "Ether"), "The amount of wei raised should be 1 Ethereum.");

    const endSupply = await COT.saleSupply.call();

    assert.closeTo(endSupply.toNumber() + nbTokens.toNumber(), startingSupply.toNumber() + prestartingSupply.toNumber(), 1000000000000000000, "The sale supply has not been correctly updated.");


  });

});
