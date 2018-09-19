pragma solidity ^0.4.24;


contract KeyValueStore {
    mapping (bytes32 => bytes) public data;
    mapping (bytes32 => bool) public created;

    mapping (bytes32 => mapping (address => bytes)) public keys;

    mapping (address => string) public registration;
    mapping (address => bool) public registered;

    mapping (bytes32 => address[]) private owners;
    mapping (bytes32 => address[]) private admins;
    mapping (bytes32 => address[]) private writers;
    mapping (bytes32 => address[]) public readers;

    function create(address account, bytes32 accessor, bytes encryptedData, bytes encryptedKey) public {
        if (created[accessor]) {
            // return;
        }
        created[accessor] = true;
        data[accessor] = encryptedData;
        owners[accessor] = [account];
        keys[accessor][account] = encryptedKey; // move to grantReadAccess
    }

    function write(bytes32 accessor, bytes encryptedData) public {
        data[accessor] = encryptedData;
    }

    function isOwner(address account) public view returns(bool) {
        return true;
    }

    function getKey(bytes32 accessor, address account) public returns(bytes) {
        return keys[accessor][account];
    }

    function setRegistration(string publicKey) public {
        registration[msg.sender] = publicKey;
        registered[msg.sender] = true;
    }
}
