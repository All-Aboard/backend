const express = require('express');
const router = express.Router();

const util = require('ethereumjs-util');
const EthereumTx = require('ethereumjs-tx');
const lightwallet = require('eth-lightwallet');
const txutils = lightwallet.txutils;

router.post('/', async (req, res, next) => {
    const {web3, contracts, addresses, MAIN_ADDR, privateKey} = req.injections;
    const {dataSign, toAddr, value} = req.body;

    getNonce(web3, MAIN_ADDR, (err, txnsCount) => {
        console.log('txnsCount', txnsCount);

        const txParams = {
            nonce: txnsCount,
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

        web3.eth.sendSignedTransaction('0x' + tx.serialize().toString('hex')).on('receipt', (receipt) => {
            console.log(receipt);
            res.send({});
        }).catch((e) => {
            console.log(e)
        });
    });
});

module.exports = router;


function getNonce(web3, address, callback) {
    web3.eth.getTransactionCount(address, (error, result) => {
        var txnsCount = result;

        callback(null, txnsCount);

        // web3.currentProvider.sendAsync({
        //     method: "txpool_content",
        //     params: [],
        //     jsonrpc: "2.0",
        //     id: new Date().getTime()
        // }, (error, result) => {
        //     if (result.result.pending) {
        //         if (result.result.pending[address]) {
        //             txnsCount = txnsCount +
        //                 Object.keys(result.result.pending[address]).length;
        //             callback(null, txnsCount);
        //         } else {
        //             callback(null, txnsCount);
        //         }
        //     } else {
        //         callback(null, txnsCount);
        //     }
        // })
    })
}