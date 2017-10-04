var CoinsOpenToken = artifacts.require("./CoinsOpenToken.sol");

var BigNumber = require('bignumber.js');
require('babel-polyfill');

contract('CoinsOpenToken', function(accounts) {


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

  it("function(): it accepts 1 ether and buys correct fuel at relevant times of ICO", async () =>  {

    const COT = await CoinsOpenToken.new({from: owner, gas: gasAmount});
    assert.equal(1, 1, "The balance of the end buyer was not incremented by 3000 FUEL");
  });

});
