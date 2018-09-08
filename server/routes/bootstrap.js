const express = require('express');
const router = express.Router();

router.post('/', async (req, res, next) => {
    const {web3} = req.injections;
    const {account, ensName, sign} = req.body;

    console.log('account, ensName, sign', account, ensName, sign);

    // TODO - Waterfall
    // 01 - Spawn the ID SC
    // 02 - Register the name under the DOMAIN_NAMEHASH sub domain (ENS)
    // 03 - Resolve the address of the ID SC with the ENS-name
    // 04 - return ok, with the result of the new address

    res.send({msg:'account created'});
});

module.exports = router;
