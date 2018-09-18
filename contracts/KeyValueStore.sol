pragma solidity ^0.4.24;


contract KeyValueStore {
    mapping (bytes32 => string) public data;
    mapping (bytes32 => bool) public created;

    mapping (bytes32 => mapping (address => string[])) public keys;

    mapping (address => string) public registration;
    mapping (address => bool) public registered;

    mapping (bytes32 => address[]) private owners;
    mapping (bytes32 => address[]) private admins;
    mapping (bytes32 => address[]) private writers;
    mapping (bytes32 => address[]) public readers;

    function create(address account, bytes32 accessor, string encryptedData, string encryptedKey) public {
        if (exists(accessor)) {
            return;
        }
        created[accessor] = true;
        data[accessor] = encryptedData;
        owners[accessor] = [account];
    }

    function exists(bytes32 accessor) public view returns(bool) {
        return created[accessor];
    }

    function setRegistration(string publicKey) public {
        registration[msg.sender] = publicKey;
        registered[msg.sender] = true;
    }
}
