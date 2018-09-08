pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/SignatureBouncer.sol";


// Copied & inspired from https://github.com/austintgriffith/bouncer-proxy/blob/master/BouncerProxy/BouncerProxy.sol
// An identity Bouncer proxy, to wrap the scenario of no-coiners users
contract Identity is SignatureBouncer {
    address userAddress;
    address registry;
    uint256 fundedAmount;

    mapping(address => uint) public nonce;

    event Received (address indexed sender, uint value);
    event Forwarded (bytes sig, address signer, address destination, uint value, bytes data,address rewardToken, uint rewardAmount,bytes32 _hash);

    constructor(address _user, address _registry, uint256 _fundedAmount) payable {
        userAddress = _user;
        registry = _registry;
        fundedAmount = _fundedAmount;
    }

    function () public payable { emit Received(msg.sender, msg.value); }

    function send(address a) public {

        // ERC20 mycrypto = ERC20(a);

    }

    function executeCall(address to, uint256 value, bytes data) internal returns (bool success) {
        assembly {
            success := call(gas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function forward(bytes sig, address signer, address destination, uint value, bytes data, address rewardToken, uint rewardAmount) public {
        // the hash contains all of the information about the meta transaction to be called
        bytes32 _hash = keccak256(abi.encodePacked(address(this), signer, destination, value, data, rewardToken, rewardAmount, nonce[signer]++));

        //this makes sure signer signed correctly AND signer is a valid bouncer
        require(isValidDataHash(_hash,sig));

        //make sure the signer pays in whatever token (or ether) the sender and signer agreed to
        // or skip this if the sender is incentivized in other ways and there is no need for a token
        if(rewardToken==address(0)){
            //ignore reward, 0 means none
        } else if(rewardToken==address(1)){
            //REWARD ETHER
            require(msg.sender.call.value(rewardAmount).gas(36000)());
        } else {
            //REWARD TOKEN
            require((ERC20(rewardToken)).transfer(msg.sender,rewardAmount));
        }

        //execute the transaction with all the given parameters
        require(executeCall(destination, value, data));
        emit Forwarded(sig, signer, destination, value, data, rewardToken, rewardAmount, _hash);
    }
}
