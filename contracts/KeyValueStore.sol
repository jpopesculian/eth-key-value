pragma solidity ^0.4.24;


contract KeyValueStore {
    mapping (bytes32 => bytes) public data;
    mapping (bytes32 => bool) public created;

    mapping (bytes32 => mapping (address => bytes)) public keys;

    mapping (address => string) public registration;
    mapping (address => bool) public registered;

    mapping (bytes32 => mapping (address => uint8)) public owners;
    mapping (bytes32 => mapping (address => uint8)) public admins;
    mapping (bytes32 => mapping (address => uint8)) public writers;
    mapping (bytes32 => mapping (address => uint8)) public readers;
    mapping (bytes32 => address[]) public members;

    function create(address account, bytes32 accessor, bytes encryptedData, bytes encryptedKey) public {
        // if (created[accessor]) return; TODO change to require()
        _create(account, accessor, encryptedData, encryptedKey);
    }

    function write(bytes32 accessor, bytes encryptedData) public {
        require(canWrite(accessor, msg.sender));
        _write(accessor, encryptedData);
    }

    function addOwner(bytes32 accessor, address account, bytes encryptedKey) public returns(uint8) {
        require(isOwner(accessor, msg.sender));
        return _addOwner(accessor, account, encryptedKey);
    }

    function addAdmin(bytes32 accessor, address account, bytes encryptedKey) public returns(uint8) {
        require(isOwner(accessor, msg.sender));
        return _addAdmin(accessor, account, encryptedKey);
    }

    function grantWriteAccess(bytes32 accessor, address account, bytes encryptedKey) public returns(uint8) {
        require(isAdmin(accessor, msg.sender));
        return _grantWriteAccess(accessor, account, encryptedKey);
    }

    function grantReadAccess(bytes32 accessor, address account, bytes encryptedKey) public returns(uint8) {
        require(isAdmin(accessor, msg.sender));
        return _grantReadAccess(accessor, account, encryptedKey);
    }

    function issueEncryptedKey(bytes32 accessor, address account, bytes encryptedKey) public {
        require(isAdmin(accessor, msg.sender));
        require(canRead(accessor, account));
        return _issueEncryptedKey(accessor, account, encryptedKey);
    }

    function removeOwner(bytes32 accessor, address account) public returns(uint8) {
        require(msg.sender != account);
        require(isOwner(accessor, msg.sender));
        return _removeOwner(accessor, account);
    }

    function removeAdmin(bytes32 accessor, address account) public returns(uint8) {
        require(msg.sender != account);
        require(isOwner(accessor, msg.sender));
        return _removeAdmin(accessor, account);
    }

    function revokeWriteAccess(bytes32 accessor, address account) public returns(uint8) {
        require(msg.sender != account);
        require(isAdmin(accessor, msg.sender));
        return _revokeWriteAccess(accessor, account);
    }

    function revokeReadAccess(bytes32 accessor, address account) public returns(uint8) {
        require(msg.sender != account);
        require(isAdmin(accessor, msg.sender));
        return _revokeReadAccess(accessor, account);
    }

    function setRegistration(string publicKey) public {
        registration[msg.sender] = publicKey;
        registered[msg.sender] = true;
    }

    // === GETTERS ===
    //
    function isOwner(bytes32 accessor, address account) public view returns(bool) {
        return owners[accessor][account] > 0;
    }

    function isAdmin(bytes32 accessor, address account) public view returns(bool) {
        return admins[accessor][account] > 0;
    }

    function canWrite(bytes32 accessor, address account) public view returns(bool) {
        return writers[accessor][account] > 0;
    }

    function canRead(bytes32 accessor, address account) public view returns(bool) {
        return readers[accessor][account] > 0;
    }

    function getKey(bytes32 accessor, address account) public view returns(bytes) {
        return keys[accessor][account];
    }

    function getMembers(bytes32 accessor) public view returns(address[]) {
        return members[accessor];
    }

    // === PRIVATE SETTERS ===
    //
    function _create(address account, bytes32 accessor, bytes encryptedData, bytes encryptedKey) private {
        created[accessor] = true;
        _write(accessor, encryptedData);
        _addOwner(accessor, account, encryptedKey);
    }

    function _write(bytes32 accessor, bytes encryptedData) private {
        data[accessor] = encryptedData;
    }

    function _addOwner(bytes32 accessor, address account, bytes encryptedKey) private returns(uint8) {
        if (isOwner(accessor, account)) {
            return owners[accessor][account];
        }
        return owners[accessor][account] = _addAdmin(accessor, account, encryptedKey);
    }

    function _addAdmin(bytes32 accessor, address account, bytes encryptedKey) private returns(uint8) {
        if (isAdmin(accessor, account)) {
            return admins[accessor][account];
        }
        return admins[accessor][account] = _grantWriteAccess(accessor, account, encryptedKey);
    }

    function _grantWriteAccess(bytes32 accessor, address account, bytes encryptedKey) private returns(uint8) {
        if (canWrite(accessor, account)) {
            return writers[accessor][account];
        }
        return writers[accessor][account] = _grantReadAccess(accessor, account, encryptedKey);
    }

    function _grantReadAccess(bytes32 accessor, address account, bytes encryptedKey) private returns(uint8) {
        if (canRead(accessor, account)) {
            return readers[accessor][account];
        }
        _issueEncryptedKey(accessor, account, encryptedKey);
        return readers[accessor][account] = _addMember(accessor, account);
    }

    function _issueEncryptedKey(bytes32 accessor, address account, bytes encryptedKey) private {
        keys[accessor][account] = encryptedKey;
    }

    function _removeOwner(bytes32 accessor, address account) private returns(uint8) {
        uint8 id = owners[accessor][account];
        if (id < 1) {
            return id;
        }
        owners[accessor][account] = 0;
        return id;
    }

    function _removeAdmin(bytes32 accessor, address account) private returns(uint8) {
        uint8 id = admins[accessor][account];
        if (id < 1) {
            return id;
        }
        admins[accessor][account] = 0;
        return _removeOwner(accessor, account);
    }

    function _revokeWriteAccess(bytes32 accessor, address account) private returns(uint8) {
        uint8 id = writers[accessor][account];
        if (id < 1) {
            return id;
        }
        writers[accessor][account] = 0;
        return _removeAdmin(accessor, account);
    }

    function _revokeReadAccess(bytes32 accessor, address account) private returns(uint8) {
        if (readers[accessor][account] < 1) {
            return readers[accessor][account];
        }
        _removeMember(accessor, account);
        readers[accessor][account] = 0;
        return _revokeWriteAccess(accessor, account);
    }

    function _addMember(bytes32 accessor, address account) private returns(uint8) {
        return uint8(members[accessor].push(account));
    }

    function _removeMember(bytes32 accessor, address account) private returns(uint8) {
        uint8 id = readers[accessor][account];
        uint8 index = id - 1;
        if (index >= members[accessor].length) return;

        delete members[accessor][index];

        address lastAccount = members[accessor][members[accessor].length - 1];
        members[accessor][index] = lastAccount;
        _changeId(accessor, account, id);

        members[accessor].length--;

        return id;
    }

    function _changeId(bytes32 accessor, address account, uint8 id) private {
        if (isOwner(accessor, account)) {
            owners[accessor][account] = id;
        }
        if (isAdmin(accessor, account)) {
            admins[accessor][account] = id;
        }
        if (canWrite(accessor, account)) {
            writers[accessor][account] = id;
        }
        if (canRead(accessor, account)) {
            readers[accessor][account] = id;
        }
    }
}
