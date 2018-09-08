const express = require('express');
const cookieParser = require('cookie-parser');
const logger = require('morgan');
const path = require('path');
const glob = require('glob');

const app = express();

const BASE_ROUTE = '/v1';

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({
    extended: false
}));
app.use(cookieParser());


[].concat(
    glob.sync('./**/*.js', {cwd: path.join(__dirname, 'routes')})
).forEach((filename) => {
    const route = filename.split('.').slice(0, -1).join('');

    app.use(`${BASE_ROUTE}${route}`, require(path.join(__dirname, 'routes', filename)));
});

app.use(`${BASE_ROUTE}`, require(path.join(__dirname, 'routes', 'index.js')));

module.exports = app;
