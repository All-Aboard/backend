const HDWalletProvider = require('truffle-hdwallet-provider');
const privateJson = require('./.private.json');

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

module.exports = {
    networks: {
        development: {
            host: 'localhost',
            port: 8545,
            network_id: '*',
            gas: 2000000,
            gasPrice: 10000000000,
        },
        [privateJson.name]: {
            provider: () => new HDWalletProvider(privateJson.mnemonic, privateJson.endpoint, 0),
            from: privateJson.address,
            network_id: privateJson.network_id,
            gas: 2000000,
            gasPrice: 20000000000,
        }
    },
    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    },
    mocha: {
        useColors: true
    }
};
