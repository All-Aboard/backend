const express = require('express');
const router = express.Router();

const util = require('ethereumjs-util');
const tx = require('ethereumjs-tx');
const lightwallet = require('eth-lightwallet');
const txutils = lightwallet.txutils;

// ENS
const ensAbis = require('../abis/ens.js');

router.post('/', async (req, res, next) => {
    const {web3, contracts, addresses, MAIN_ADDR, ENS_REGISTRY_ROPSTEN, ENS_RESOLVER_ROPSTEN } = req.injections;
    const {account, ensName, sign} = req.body;

    console.log('account, ensName, sign', account, ensName, sign);

    // Waterfall of creation

    // 01 - Spawn the ID SC
    const IdentityContract = new web3.eth.Contract(contracts.Identity.abi, null);

    const identity = await (IdentityContract.deploy({
        data: contracts.Identity.bytecode,
        arguments: [account, addresses.AllianceRegistry, 0]
    }).send({
        from: MAIN_ADDR,
        gas: 2000000,
        gasPrice: 20000000000,
    }));

    console.log(identity.options.address);

    

    // 02 - Register the name under the DOMAIN_NAMEHASH sub domain (ENS)
    
    //      2.1 -  instantiate the ENS Registry and Resolver
    const ensRegistry = new web3.eth.Contract(
        ensAbis.ENS_REGISTRY,
        ENS_REGISTRY_ROPSTEN
      )

    const ensResolver = new web3.eth.Contract(
        ensAbis.ENS_RESOLVER,
        ENS_RESOLVER_ROPSTEN
      )
      
    //console.log("ENS-REGISTRY: ", ensRegistry);  
    //console.log("ENS-RESOLVER: ", ensResolver);

    //      2.2 - register the domain under the namehas


    
    
    // 03 - Resolve the address of the ID SC with the ENS-name
    
    // 04 - return ok, with the result of the new address

    res.send({address: identity.options.address});
});

module.exports = router;
