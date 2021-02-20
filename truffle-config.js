require('babel-register');
require('babel-polyfill');

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      gas: 60000000,
      network_id: "*" // Match any network id
    },
  },
  contracts_directory: './src/contracts/',
  contracts_build_directory: './src/abis/',
  compilers: {
    solc: {
      version: "^0.6",
      optimizer: {
        enabled: true,
        runs: 1000
      },
      evmVersion: "petersburg",
      allowUnlimitedContractSize: true
    }
  },
  solc: {
    version: "^0.6",
    optimizer: {
      enabled: true,
      runs: 1000
    },
    evmVersion: "petersburg",
    allowUnlimitedContractSize: true
  }
}
