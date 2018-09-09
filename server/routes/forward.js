const express = require('express');
const router = express.Router();

const util = require('ethereumjs-util');
const EthereumTx = require('ethereumjs-tx');
const lightwallet = require('eth-lightwallet');
const txutils = lightwallet.txutils;

let Nonce = 40

router.post('/', async (req, res, next) => {
    const {web3, contracts, addresses, MAIN_ADDR, privateKey} = req.injections;
    const {dataSign, toAddr, value} = req.body;

    const txParams = {
        nonce: (Nonce+=10),
        gasLimit: web3.utils.toHex(5000000),
        gasPrice: web3.utils.toHex(100000000000),
        to: toAddr,
        value: value || '0x00',
        from: MAIN_ADDR,
        data: dataSign
    };

    const tx = new EthereumTx(txParams);
    tx.sign(privateKey);

    console.log(tx.serialize().toString('hex'));

    web3.eth.sendSignedTransaction('0x' + tx.serialize().toString('hex')).on('receipt', console.log).catch( (e) => {
        console.log(e)
        res.send({});
    });
});

module.exports = router;
