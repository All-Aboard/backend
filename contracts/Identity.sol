pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract Identity {

    address userAddress;
    address registry;

    constructor(address _user, address _registry) payable {
        userAddress = _user;
        registry = _registry;
    }

    function send(address a) public {

        // ERC20 mycrypto = ERC20(a);

    }

    function() public payable {

    }

}
