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

  it("Distributing reserve tokens is protected", async () =>  {

    const COT = await CoinsOpenToken.new({from: owner, gas: gasAmount});
    const reserveSupply = await COT.reserveSupply.call();

    const startingBalance = await COT.balanceOf(buyer2, {from: buyer1, gas: gasAmount});
    try {
      await COT.distributeReserveSupply(200000000, buyer2, {from: buyer1, gas: gasAmount});
    } catch(e) {
      assert.equal(true, true, "Token could be sent");
    }
    const endBalance = await COT.balanceOf(buyer2, {from: buyer1, gas: gasAmount});
    const endreserveSupply = await COT.reserveSupply.call();

    assert.equal(startingBalance.toNumber(), endBalance.toNumber(), "Token were distributed");
    assert.equal(endreserveSupply.toNumber(), reserveSupply.toNumber(), "Supply changed");

  });

  it("Distributing reserve tokens is done by owner", async () =>  {

    const COT = await CoinsOpenToken.new({from: owner, gas: gasAmount});
    const reserveSupply = await COT.reserveSupply.call();

    await COT.distributeReserveSupply(200000000, buyer2, {from: owner, gas: gasAmount});
    const endBalance = await COT.balanceOf(buyer2, {from: buyer1, gas: gasAmount});
    const endreserveSupply = await COT.reserveSupply.call();

    assert.equal(200000000, endBalance.toNumber(), "The owner can transfer reserve tokens");
    assert.equal(endreserveSupply.toNumber(), reserveSupply.toNumber() - 200000000, "Supply did not changed");

  });


});
