pragma solidity ^0.4.24;

import "./Identity.sol";

contract AllianceRegistry {
    uint constant MIN_VALUE = 10 finney;
    uint256 runningBalance;

    mapping(address => bool) public allianceMembers;

    event ReceivedFunds (address indexed member, uint value);
    event IdentityCreated (address indexed user, address indexed identity, address indexed member);
    event MemberAdded (address indexed member, address indexed sender);

    modifier membersOnly() {
        require(allianceMembers[msg.sender] == true, "Only Alliance Members are allowed");
        _;
    }

    constructor() public payable {
        allianceMembers[msg.sender] = true;

       // check isnt needed - msg.value can be 0 and its fine to add 0
       // if (msg.value > 0) {
            runningBalance += msg.value;
       // }
    }

    function createIdentity(address _user) public payable membersOnly {
        uint256 amountToFund = 0;

        if (msg.value > 0) {
            require(msg.value >= MIN_VALUE, "Minimum payable amount is required");
            amountToFund = msg.value;
        } else {
            require(runningBalance >= MIN_VALUE, "Running Balance is required to be greater than the Minimum");

            amountToFund = MIN_VALUE;
        }

        Identity idInstance = (new Identity).value(amountToFund)(_user, address(this));

        address(idInstance).transfer(amountToFund);

        emit IdentityCreated(_user, address(idInstance), msg.sender);
    }

    function addMember(address _member) public membersOnly {
        allianceMembers[_member] = true;

        emit MemberAdded(_member, msg.sender);
    }

    // Only alliance members can fun this
    function () payable membersOnly {
        // ?? you may wanna add to running balance? 
        emit ReceivedFunds(msg.sender, msg.value);
    }
}