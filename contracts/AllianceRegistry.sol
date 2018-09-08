pragma solidity ^0.4.24;

import "./Identity.sol";

contract AllianceRegistry {
    uint constant MIN_VALUE = 10 finney;

    mapping(address => bool) public allianceMembers;

    event IdentityCreated (address indexed user, address indexed identity, address indexed member);
    event MemberAdded (address indexed member, address indexed sender);

    modifier membersOnly() {
        require(allianceMembers[msg.sender] == true, "Only Alliance Members are allowed");
        _;
    }

    constructor() public {
        allianceMembers[msg.sender] = true;
    }

    function createIdentity(address _user, address _tokenAddress) public payable membersOnly() {
        require(msg.value >= MIN_VALUE, "Minimum payable amount is required");

        Identity idInstance = new Identity(_user, address(this));

        emit IdentityCreated(_user, address(idInstance), msg.sender);
    }

    function addMember(address _member) public membersOnly() {
        allianceMembers[_member] = true;

        emit MemberAdded(_member, msg.sender);
    }
}
