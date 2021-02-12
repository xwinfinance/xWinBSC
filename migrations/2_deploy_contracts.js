const WINTOKEN = artifacts.require("xWinToken.sol");
const xWinTimeLockVault = artifacts.require("xWinTimeLockVault.sol");
const xWinMaster = artifacts.require("xWinMaster.sol");
const Mock = artifacts.require("Mock.sol");
const xWinStake = artifacts.require("xWinStake.sol");
const xWinDefi = artifacts.require("xWinDefi.sol");
const xWinFund = artifacts.require("xWinFund.sol");
const SampleToken1 = artifacts.require("SampleToken.sol");
const SampleTokenBTC = artifacts.require("SampleTokenBTC.sol");


const managerAddress = "0xD1D0ad5a6DA5279012B613f3A4889A4039283565"
const maxSupply = web3.utils.toBN(100*(10**18))

module.exports = (deployer, network, [owner]) => {
  return deployer
    .then(() => deployer.deploy(SampleTokenBTC, "BTC", "BTC", 18, maxSupply))
    .then(() => deployer.deploy(SampleToken1, "ETH", "ETH", 18, maxSupply))
    .then(() => deployer.deploy(WINTOKEN, maxSupply))
    .then(() => deployer.deploy(xWinTimeLockVault, "xWin Team Vault", 1, WINTOKEN.address))
    .then(() => deployer.deploy(Mock))
    .then(() => deployer.deploy(xWinMaster, Mock.address, Mock.address))
    .then(() => deployer.deploy(xWinStake, "xWin Stake Helper", Mock.address))
    .then(() => deployer.deploy(xWinDefi, 50, managerAddress, managerAddress, xWinStake.address, WINTOKEN.address))
    .then(() => deployer.deploy(xWinFund, "Test Fund", "XFUND", xWinDefi.address, managerAddress, 100, xWinMaster.address))
};


