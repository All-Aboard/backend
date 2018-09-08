pragma solidity ^0.4.24;

import "./Identity.sol";

contract AllianceRegistry {

    mapping(address => bool ) public allianceMembers;

    // mapping(bytes32 => address ) public allianceMembers;

    constructor() public {}

    function createIdentity(address _user, address _tokenAddress) public {
        require(allianceMembers[msg.sender] == true);
        // Identity a = new Identity(_user, address(this));

    }


    function addMember() public {}


}
