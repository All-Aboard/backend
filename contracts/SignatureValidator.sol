pragma solidity ^0.4.24;

contract SignatureValidator {
    function checkSignature(bytes32 _messageHash, bytes32 _r, bytes32 _s, uint8 _v, address userAddress)
    public pure returns (bool) {
        return recoverAddress(_messageHash,  _r, _s, _v) == userAddress;
    }

    function recoverAddress(bytes32 _messageHash, bytes32 _r, bytes32 _s, uint8 _v)
    internal pure returns (address) {
        return ecrecover(_messageHash, _v, _r, _s);
    }
}
