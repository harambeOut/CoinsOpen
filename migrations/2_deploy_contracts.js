var SafeMath = artifacts.require("./SafeMath.sol");
var CoinsOpenToken = artifacts.require("./CoinsOpenToken.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.link(SafeMath, CoinsOpenToken);
  deployer.deploy(CoinsOpenToken);
};
