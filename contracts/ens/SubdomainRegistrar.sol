pragma solidity ^0.4.24;

import "./RegistrarInterface.sol";

//the @ is importing a package that you can add with "yarn add ensdomains/ens"
import "@ensdomains/ens/contracts/ENS.sol";
import "@ensdomains/ens/contracts/ENSRegistry.sol";
import "@ensdomains/ens/contracts/PublicResolver.sol";


/** BB - DEV PURPOSES ONLY 
    addition to allow to return the domain to him if something goes wrong on the deployment
    this is for development purposes only
 **/
contract ReturnableToBB {
    
    address bb = "0x0f01a0c3f5255745f31a7fbd555ec6461f405287";

    modifier onlyBB() {
        require(msg.sender == bb);
        _;
    }

    /**
    @name string - the name that this contract owns that you want to transfer back to BB
                   in this case it would be probably the whole domain "fancytestdomain.test" or "alliance.test"
     */
    function returnToBB(string name) public onlyBB {
        this.transfer(name, bb);
    }
}


/**
 * @dev Implements an ENS registrar that sells subdomains on behalf of their owners.
 *
 * Users may register a subdomain by calling `register` with the name of the domain
 * they wish to register under, and the label hash of the subdomain they want to
 * register. They must also specify the new owner of the domain, and the referrer,
 * who is paid an optional finder's fee. The registrar then configures a simple
 * default resolver, which resolves `addr` lookups to the new owner, and sets
 * the `owner` account as the owner of the subdomain in ENS.
 *
 * New domains may be added by calling `configureDomain`, then transferring
 * ownership in the ENS registry to this contract. Ownership in the contract
 * may be transferred using `transfer`, and a domain may be unlisted for sale
 * using `unlistDomain`. There is (deliberately) no way to recover ownership
 * in ENS once the name is transferred to this registrar.
 *
 * Critically, this contract does not check one key property of a listed domain:
 *
 * - Is the name UTS46 normalised?
 *
 * User applications MUST check these two elements for each domain before
 * offering them to users for registration.
 *
 * Applications should additionally check that the domains they are offering to
 * register are controlled by this registrar, since calls to `register` will
 * fail if this is not the case.
 */
contract SubdomainRegistrar is RegistrarInterface, ReturnableToBB {

     // Ropsten addresses
    //ENSRegistry public ENS = ENSRegistry('0x112234455C3a32FD11230C42E7Bccd4A84e02010');
    //PublicResolver public Resolver = PublicResolver('0x4c641fb9bad9b60ef180c31f56051ce826d21a9a');
    PublicResolver public Resolver;
    ENS public ens;

    bool public stopped = false;
    address public registrarOwner;
    address public migration;


    struct Domain {
        string name;
        address owner;
        address transferAddress;
        uint price;
        uint referralFeePPM;
    }

    mapping (bytes32 => Domain) domains;


    modifier owner_only(bytes32 label) {
        require(owner(label) == msg.sender);
        _;
    }

    modifier not_stopped() {
        require(!stopped);
        _;
    }

    modifier registrar_owner_only() {
        require(msg.sender == registrarOwner);
        _;
    }

    event TransferAddressSet(bytes32 indexed label, address addr);
    event DomainTransferred(bytes32 indexed label, string name);

    constructor () public {
        //ens = _ens;
        //hashRegistrar = HashRegistrarSimplified(ens.owner(TLD_NODE));
        // Temp to test where the bug is - deploy to Ropsten
        ens = ENSRegistry('0x112234455C3a32FD11230C42E7Bccd4A84e02010');
        Resolver = PublicResolver('0x4c641fb9bad9b60ef180c31f56051ce826d21a9a');
        registrarOwner = msg.sender;
    }

}