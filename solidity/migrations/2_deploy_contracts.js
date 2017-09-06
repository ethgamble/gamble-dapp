
var Gamble = artifacts.require("./Gamble.sol");

module.exports = function(deployer) {
    deployer.deploy(Gamble, 'Gamble Token', 'GBT', 0, {value: Math.pow(10, 18)});
};
