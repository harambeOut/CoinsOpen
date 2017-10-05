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

  it("Distributing dividends", async () =>  {

    const COT = await CoinsOpenToken.new({from: owner, gas: gasAmount});
    const reserveSupply = await COT.reserveSupply.call();
    const totalSupply = await COT.totalSupply.call();
    await COT.distributeReserveSupply(5000000000000000000000000, buyer2, {from: owner, gas: gasAmount});
    const endBalance = await COT.balanceOf(buyer2, {from: owner, gas: gasAmount});
    assert.equal(5000000000000000000000000, endBalance.toNumber(), "The balance of user is correct");
    await COT.giveDividend({from: owner, gas: gasAmount, value: web3.toWei("10", "Ether")});
    await COT.checkDividend(buyer2, {from: owner, gas: gasAmount});
    const afterdididend = await COT.balanceOf(buyer2, {from: owner, gas: gasAmount});
    assert.equal(afterdididend.toNumber(), endBalance.toNumber() + web3.toWei("10", "Ether") / totalSupply.toNumber(), "The balance of user is correct");

  });

  it("Distributing dividends multiple times", async () =>  {

    const COT = await CoinsOpenToken.new({from: owner, gas: gasAmount});
    const reserveSupply = await COT.reserveSupply.call();
    const totalSupply = await COT.totalSupply.call();
    await COT.distributeReserveSupply(5000000000000000000000000, buyer2, {from: owner, gas: gasAmount});
    const endBalance = await COT.balanceOf(buyer2, {from: owner, gas: gasAmount});
    assert.equal(5000000000000000000000000, endBalance.toNumber(), "The balance of user is correct");
    await COT.giveDividend({from: owner, gas: gasAmount, value: web3.toWei("8", "Ether")});

    await COT.giveDividend({from: owner, gas: gasAmount, value: web3.toWei("2", "Ether")});

    await COT.checkDividend(buyer2, {from: owner, gas: gasAmount});
    const afterdididend = await COT.balanceOf(buyer2, {from: owner, gas: gasAmount});
    assert.equal(afterdididend.toNumber(), endBalance.toNumber() + web3.toWei("10", "Ether") / totalSupply.toNumber(), "The balance of user is correct");

  });

});
