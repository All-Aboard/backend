pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ECRecovery.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";


contract Identity is Ownable {
    using ECRecovery for bytes32;
    using SafeMath for uint256;

    constructor() public { }

    function () public payable {
        emit Received(msg.sender, msg.value);
    }

    event Received (address indexed sender, uint value);
    event ExecuteExecution(
        address indexed from, //the subscriber
        address indexed to, //the publisher
        address tokenAddress, //the token address paid to the publisher
        uint256 tokenAmount, //the token amount paid to the publisher
        uint256 periodSeconds, //the period in seconds between payments
        address gasToken, //the address of the token to pay relayer (0 for eth)
        uint256 gasPrice, //the amount of tokens or eth to pay relayer (0 for free)
        address gasPayer //the address that will pay the tokens to the relayer
    );
    event FailedExecuteExecution(
        address indexed from, //the subscriber
        address indexed to, //the publisher
        address tokenAddress, //the token address paid to the publisher
        uint256 tokenAmount, //the token amount paid to the publisher
        uint256 periodSeconds, //the period in seconds between payments
        address gasToken, //the address of the token to pay relayer (0 for eth)
        uint256 gasPrice, //the amount of tokens or eth to pay relayer (0 for free)
        address gasPayer //the address that will pay the tokens to the relayer
    );

    // for some cases of delegated execution, this contract will pay a third party
    // to execute the transfer. If this happens, the owner of this contract must
    // sign the executionHash
    mapping(bytes32 => bool) public publisherSigned;

    // only the owner of this contract can sign the executionHash to whitelist
    // a specific subscription to start rewarding the relayers for paying the
    // gas of the transactions out of the balance of this contract
    function signExecutionHash(bytes32 executionHash)
        public
        onlyOwner
        returns(bool)
    {
        publisherSigned[executionHash] = true;
        return true;
    }

    // this is used by external smart contracts to verify on-chain that a
    // particular subscription is "paid" and "active"
    // there must be a small grace period added to allow the publisher
    // or desktop miner to execute
    function isExecutionActive(
        bytes32 executionHash,
        uint256 gracePeriodSeconds
    )
        external
        view
        returns (bool)
    {
        return (block.timestamp >=
                    nextValidTimestamp[executionHash].add(gracePeriodSeconds)
        );
    }

    // given the subscription details, generate a hash and try to kind of follow
    // the eip-191 standard and eip-1077 standard from my dude @avsa
    function getExecutionHash(
        address from, //the subscriber
        address to, //the publisher
        address tokenAddress, //the token address paid to the publisher
        uint256 tokenAmount, //the token amount paid to the publisher
        uint256 periodSeconds, //the period in seconds between payments
        address gasToken, //the address of the token to pay relayer (0 for eth)
        uint256 gasPrice, //the amount of tokens or eth to pay relayer (0 for free)
        address gasPayer //the address that will pay the tokens to the relayer
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                byte(0x19),
                byte(0),
                address(this),
                from,
                to,
                tokenAddress,
                tokenAmount,
                periodSeconds,
                gasToken,
                gasPrice,
                gasPayer
        ));
    }

    //ecrecover the signer from hash and the signature
    function getExecutionSigner(
        bytes32 executionHash, //hash of subscription
        bytes signature //proof the subscriber signed the meta trasaction
    )
        public
        pure
        returns (address)
    {
        return executionHash.toEthSignedMessageHash().recover(signature);
    }

    //check if a subscription is signed correctly and the timestamp is ready for
    // the next execution to happen
    function isExecutionReady(
        address from, //the subscriber
        address to, //the publisher
        address tokenAddress, //the token address paid to the publisher
        uint256 tokenAmount, //the token amount paid to the publisher
        uint256 periodSeconds, //the period in seconds between payments
        address gasToken, //the address of the token to pay relayer (0 for eth)
        uint256 gasPrice, //the amount of tokens or eth to pay relayer (0 for free)
        address gasPayer, //the address that will pay the tokens to the relayer
        bytes signature //proof the subscriber signed the meta trasaction
    )
        public
        view
        returns (bool)
    {
        bytes32 executionHash = getExecutionHash(
            from, to, tokenAddress, tokenAmount, periodSeconds, gasToken, gasPrice, gasPayer
        );
        address signer = getExecutionSigner(executionHash, signature);
        uint256 allowance = ERC20(tokenAddress).allowance(from, address(this));
        return (
            signer == from &&
            block.timestamp >= nextValidTimestamp[executionHash] &&
            allowance >= tokenAmount
        );
    }

    // you don't really need this if you are using the approve/transferFrom method
    // because you control the flow of tokens by approving this contract address,
    // but to make the contract an extensible example for later user I'll add this
    function cancelExecution(
        address from, //the subscriber
        address to, //the publisher
        address tokenAddress, //the token address paid to the publisher
        uint256 tokenAmount, //the token amount paid to the publisher
        uint256 periodSeconds, //the period in seconds between payments
        address gasToken, //the address of the token to pay relayer (0 for eth)
        uint256 gasPrice, //the amount of tokens or eth to pay relayer (0 for free)
        address gasPayer, //the address that will pay the tokens to the relayer
        bytes signature //proof the subscriber signed the meta trasaction
    )
        public
        returns (bool success)
    {
        bytes32 executionHash = getExecutionHash(
            from, to, tokenAddress, tokenAmount, periodSeconds, gasToken, gasPrice, gasPayer
        );
        address signer = executionHash.toEthSignedMessageHash().recover(signature);

        //the signature must be valid
        require(signer == from, "Invalid Signature for subscription cancellation");

        //since we can't underflow (SAFEMATH!), we'll just set it to a large number
        nextValidTimestamp[executionHash]=99999999999; //subscription will become valid again Wednesday, November 16, 5138 9:46:39 AM
        //at this point the nextValidTimestamp should be a timestamp that will never
        //be reached during the brief window human existence

        return true;
    }

    // execute the transferFrom to pay the publisher from the subscriber
    // the subscriber has full control by approving this contract an allowance
    function executeExecution(
        address from, //the subscriber
        address to, //the publisher
        address tokenAddress, //the token address paid to the publisher
        uint256 tokenAmount, //the token amount paid to the publisher
        uint256 periodSeconds, //the period in seconds between payments
        address gasToken, //the address of the token to pay relayer (0 for eth)
        uint256 gasPrice, //the amount of tokens or eth to pay relayer (0 for free)
        address gasPayer, //the address that will pay the tokens to the relayer
        bytes signature //proof the subscriber signed the meta trasaction
    )
        public
        returns (bool success)
    {
        // make sure the subscription is valid and ready
        // pulled this out so I have the hash, should be exact code as "isExecutionReady"
        bytes32 executionHash = getExecutionHash(
            from, to, tokenAddress, tokenAmount, periodSeconds, gasToken, gasPrice, gasPayer
        );
        address signer = getExecutionSigner(executionHash, signature);

        //the signature must be valid
        require(signer == from, "Invalid Signature");
        //timestamp must be equal to or past the next period
        require(
            block.timestamp >= nextValidTimestamp[executionHash],
            "Execution is not ready"
        );





        // increment the next valid period time
        //if (nextValidTimestamp[executionHash] == 0) {

            //I changed this to always use the timestamp
            // this means desktop miners MUST submit transactions as fast as possible
            // or subscriptions will start to lag
            // the upside of doing it this way is the approve/allowance of the erc20
            // can now pause and restart the subscription whenever they want
            nextValidTimestamp[executionHash] = block.timestamp.add(periodSeconds);

            //if you would like your subscription to be able to submit multiple months
            // all at once, switch back to the uncommented method, but if the subscriber
            // pauses the allowance and then later approves... a bunch of funds can all
            // move at once as you work through past months of unpaid subscriptions


        //} else {
        //      nextValidTimestamp[executionHash] =
        //        nextValidTimestamp[executionHash].add(periodSeconds);
        //}

        // now, let make the transfer from the subscriber to the publisher
        bool result = ERC20(tokenAddress).transferFrom(from,to,tokenAmount);
        if (result) {
            emit ExecuteExecution(
                from, to, tokenAddress, tokenAmount, periodSeconds, gasToken, gasPrice, gasPayer
            );
        } else {
            emit FailedExecuteExecution(
                from, to, tokenAddress, tokenAmount, periodSeconds, gasToken, gasPrice, gasPayer
            );
        }

        // it is possible for the subscription execution to be run by a third party
        // incentivized in the terms of the subscription with a gasToken and gasPrice
        // pay that out now...
        if (gasPrice > 0) {
            if (gasToken == address(0)) {
                // this is an interesting case where the service will pay the third party
                // ethereum out of the subscription contract itself
                // for this to work the publisher must send ethereum to the contract
                require(
                    from == owner || publisherSigned[executionHash],
                    "Publisher has not signed this executionHash"
                );

                require(msg.sender.call.value(gasPrice).gas(36000)(),//still unsure about how much gas to use here
                        "Execution contract failed to pay ether to relayer"
                );
            } else if (gasPayer == address(this) || gasPayer == address(0)) {
                // in this case, this contract will pay a token to the relayer to
                // incentivize them to pay the gas for the meta transaction
                // for security, the publisher must have signed the executionHash
                require(from == owner || publisherSigned[executionHash],
                        "Publisher has not signed this executionHash"
                );

                require(ERC20(gasToken).transfer(msg.sender, gasPrice),
                        "Failed to pay gas as contract"
                );
            } else if (gasPayer == from) {
                // in this case the relayer is paid with a token from the subscriber
                // this works best if it is the same token being transferred to the
                // publisher because it is already in the allowance
                require(
                    ERC20(gasToken).transferFrom(from, msg.sender, gasPrice),
                    "Failed to pay gas as from account"
                );
            } else {
                // the subscriber could craft the gasPayer to be a fellow subscriber that
                // that has approved this contract to move tokens and then exploit that
                // don't allow that...
                revert("The gasPayer is invalid");
                // on the other hand it might be really cool to allow *any* account to
                // pay the third party as long as they have approved this contract
                // AND the publisher has signed off on it. The downside would be a
                // publisher not paying attention and signs a subscription that attacks
                // a different subscriber
            }
        }

        return result;
    }
}
