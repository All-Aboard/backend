- Team name: ENTER CRYPTO / ALL ABOARD
- Team members: @lyricalpolymath, @Kyrrui, @epappas, @ali2251, @amy-jung
(standing on the shoulders of giants): @austintgriffith and more
- Network: Ropsten

All Aboard is an UX flow & architecture to on-board no coiners, giving them a wallet & ETH to start operating on the blockchain. 
These new users won't need to manage private keys, understand gas, or install browser plugins (like Metamask).

Hack Idea:
Problem: Today, Crypto is only for the initiated. To buy a domain or do anything else on ethereum, you need to be an advanced user (own a wallet and some Ether or toekns, which implies you've gone through an exchange and their lengthy KYC process)

We propose a new UX flow (that is partially based on the excellent “universal logins” pattern by Alex Van De Sande), which aims at on-boarding no coiners, users that know nothing about the blockchain, giving them an ENS Name, a wallet and some tokens to start operating on the blockchain.

This process has some costs, both to pay for the gas, for the deployment of the contracts, eventually for the registration of the name and some tokens or ETH to incentivise the users. 

Solution:

It’s the Web3 version of the "customer acquisition cost" and we propose that it should be shared among the dapps of the space: we need to onboard the users onto the blockchain before onboarding them on a dapp.

We will present the mechanisms (UX, smart contracts, and token dynamics) that will incentivise partners to participate in this **Alliance for Mass Adoption**, share the customer acquisition costs and offer new users a simple, guided and effective entry point into crypto.

**The novel proposal is that the Alliance also give a tiny allowance to the user (ie 1 ETH) that she can spend ONLY to use the Dapps of the other members of the alliance.** 
This allows to have a light account to start using dapps on the blockchain, and at the same time partially dissuades spammers because the funds can only be spent on the dapps of the alliance and can't be siphoned away.


Architecture:

There are 4 main parts:
##1. Browser based "Invisible and Etherless Accounts"
These are Ethereum accounts (with their public+private keys) that are generated on the user's browers (laptop and/or mobile) and that are called "invisible" because the user will never actually see their address or their balance. They are used only to control their Identity Contract

##2. Identity contract
This is a smart contract that represents the user's address; it has their ENS name (username.alliance.eth), the ETH allowance that is given to them by the Alliance, and it conforms to [Alex Van de Sande's](http://twitter.com/avsa) "Universal Logins pattern", whereas the real account of the user is a smart contract deployed on the blockchain and that authorizes a number of other private keys to act on its behalf, a pattern that allows the user to avoid having to deal with private keys. Besides the functionality of the allowance, the account can be used for anything the user wants (receive, send, buy tokens, execute non alliance dapps, etc) but all with the user's own earned Ether, not with the allowance.

##3. Alliance Registry (and Identity Factory)
This Smart Contract serves a double purpose: on one side it behaves like a factory of "identity contract" because it creates them for the user, as such it will pay the gas fee and also give them their ETH allowance;
the second and most important role is that of being a registry of the Dapps of the Alliance where the user can spend their freshly given allowance.
A possibility for the future is that this registry, and the Alliance, can be regulated through a DAO.

##4. Alliance MetaTransaction Web Service
This is an off-chain Web service that is based on the MetaTransactions pattern by [Austin Griffith](http://github.com/austintgriffith)
which basically picks up requests of transactions from browser based private keys ("invisible and etherless accounts") and it executes them. When it executes the transactions, it will withdraw the gas fees and any other ETH balance required by the transactions themselves from the Identity contract of the user.

