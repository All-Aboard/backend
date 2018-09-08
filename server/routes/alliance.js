const express = require('express');
const router = express.Router();

router.post('/addMember', async (req, res, next) => {
    const {web3} = req.injections;
    const {orgName, erc20Addr} = req.body;

    // TODO - Waterfall
    // 01 - hash orgName
    // 02 - call addMember(byte32, erc20Addr);

    res.send({});
});

router.post('/createIdentity', async (req, res, next) => {
    const {web3} = req.injections;
    const {orgName, erc20Addr} = req.body;

    // TODO - Waterfall
    // 01 - hash orgName
    // 02 - call addMember(byte32, erc20Addr);

    res.send({});
});

module.exports = router;
