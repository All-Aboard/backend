const express = require('express');
const cookieParser = require('cookie-parser');
const logger = require('morgan');
const path = require('path');
const glob = require('glob');
const helmet = require('helmet');
const cors = require('cors');

const app = express();

const Web3 = require('web3');

const web3 = new Web3();

const BASE_ROUTE = '/v1';

const HTTP_PROVIDER = 'http://0.0.0.0:8545';
// namehash for alliance.test
const DOMAIN_NAMEHASH = '0x09125397bb87f08c0fb3ae6e467c0da2e02b464c0b0aed09ef6578fd5d7119dd'

const accounts = [];
const contracts = {};

web3.setProvider(new web3.providers.HttpProvider(HTTP_PROVIDER));

app.use(logger('dev'));
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({
    extended: false
}));
app.use(cookieParser());

web3.eth.getAccounts().then((accList) => {
    accList.forEach((acc, i) => accounts[i] = acc);
    console.log('Accounts:', accounts);
});

app.use((req, res, next) => {
    req.injections = {
        web3, accounts, contracts, DOMAIN_NAMEHASH
    };

    next();
});

[].concat(
    glob.sync('./**/*.js', {cwd: path.join(__dirname, 'routes')})
).forEach((filename) => {
    const route = filename.split('.').slice(0, -1).join('');

    app.use(`${BASE_ROUTE}${route}`, require(path.join(__dirname, 'routes', filename)));
});

app.use(`${BASE_ROUTE}`, require(path.join(__dirname, 'routes', 'index.js')));

module.exports = app;
