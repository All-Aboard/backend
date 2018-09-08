const express = require('express');
const cookieParser = require('cookie-parser');
const logger = require('morgan');
const path = require('path');
const glob = require('glob');
const helmet = require('helmet');

const app = express();

const Web3 = require('web3');

const web3 = new Web3();

const BASE_ROUTE = '/v1';

const HTTP_PROVIDER = 'http://0.0.0.0:8545';

const accounts = [];
const contracts = {};

web3.setProvider(new web3.providers.HttpProvider(HTTP_PROVIDER));

app.use(logger('dev'));
app.use(helmet());
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
        web3, accounts,contracts
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
