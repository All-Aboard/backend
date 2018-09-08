// https://truffleframework.com/docs/truffle/getting-started/running-migrations
var Migrations = artifacts.require("./Migrations.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
