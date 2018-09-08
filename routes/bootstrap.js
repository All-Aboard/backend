const express = require('express');
const router = express.Router();

router.post('/', async (req, res, next) => {
    const {web3} = req.injections;
    const {account, ensName, sign} = req.body;

    console.log('account, ensName, sign', account, ensName, sign);

    res.send({msg:'account created'});
});

module.exports = router;
