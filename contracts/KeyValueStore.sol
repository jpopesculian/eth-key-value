pragma solidity ^0.4.24;

// import "./ArrayUtils.sol";
//

contract KeyValueStore {
    mapping (bytes32 => bytes) public data;
    mapping (bytes32 => bool) public claimed;

    mapping (bytes32 => mapping (address => bytes)) public keys;

    mapping (address => string) public registration;
    mapping (address => bool) public registered;

    struct MemberList {
        mapping (address => uint8) owners;
        mapping (address => uint8) admins;
        mapping (address => uint8) writers;
        mapping (address => uint8) readers;
        address[] accounts;
    }

    mapping (bytes32 => MemberList) internal members;
    //
    // mapping (bytes32 => mapping (address => uint8)) public owners;
    // mapping (bytes32 => mapping (address => uint8)) public admins;
    // mapping (bytes32 => mapping (address => uint8)) public writers;
    // mapping (bytes32 => mapping (address => uint8)) public readers;
    // mapping (bytes32 => address[]) public members;

    function create(address account, bytes32 accessor, bytes encryptedData, bytes encryptedKey) public {
        require(!claimed[accessor]);
        _create(account, accessor, encryptedData, encryptedKey);
    }

    function claim(address account, bytes32 accessor) public {
        require(!claimed[accessor]);
        _claim(account, accessor);
    }

    function write(bytes32 accessor, bytes encryptedData) public {
        require(canWrite(accessor, msg.sender));
        _write(accessor, encryptedData);
    }

    function addOwner(bytes32 accessor, address account /*, bytes encryptedKey */) public returns(uint8) {
        require(isOwner(accessor, msg.sender));
        // return _addOwner(accessor, account, encryptedKey);
        return _addOwner(accessor, account);
    }

    function addAdmin(bytes32 accessor, address account /*, bytes encryptedKey */) public returns(uint8) {
        require(isOwner(accessor, msg.sender));
        // return _addAdmin(accessor, account, encryptedKey);
        return _addAdmin(accessor, account);
    }

    function grantWriteAccess(bytes32 accessor, address account /*, bytes encryptedKey */) public returns(uint8) {
        require(isAdmin(accessor, msg.sender));
        // return _grantWriteAccess(accessor, account, encryptedKey);
        return _grantWriteAccess(accessor, account);
    }

    function grantReadAccess(bytes32 accessor, address account /*, bytes encryptedKey */) public returns(uint8) {
        require(isAdmin(accessor, msg.sender));
        // return _grantReadAccess(accessor, account, encryptedKey);
        return _grantReadAccess(accessor, account);
    }

    function issueEncryptedKey(bytes32 accessor, address account, bytes encryptedKey) public {
        require(isAdmin(accessor, msg.sender));
        require(canRead(accessor, account));
        return _issueEncryptedKey(accessor, account, encryptedKey);
    }

    function removeOwner(bytes32 accessor, address account) public returns(uint8) {
        require(msg.sender != account);
        require(isOwner(accessor, account));
        require(isOwner(accessor, msg.sender));
        return _removeOwner(accessor, account);
    }

    function removeAdmin(bytes32 accessor, address account) public returns(uint8) {
        require(msg.sender != account);
        require(isAdmin(accessor, account));
        require(isOwner(accessor, msg.sender));
        return _removeAdmin(accessor, account);
    }

    function revokeWriteAccess(bytes32 accessor, address account) public returns(uint8) {
        require(msg.sender != account);
        require(canWrite(accessor, account));
        if (isAdmin(accessor, account)) {
            require(isOwner(accessor, msg.sender));
        } else {
            require(isAdmin(accessor, msg.sender));
        }
        return _revokeWriteAccess(accessor, account);
    }

    function revokeReadAccess(
        bytes32 accessor,
        address account
        // bytes encryptedData,
        // bytes encryptedKey
    ) public returns(uint8) {
        require(msg.sender != account);
        require(canRead(accessor, account));
        if (isAdmin(accessor, account)) {
            require(isOwner(accessor, msg.sender));
        } else {
            require(isAdmin(accessor, msg.sender));
        }
        // return _revokeReadAccess(accessor, account, encryptedData, encryptedKey);
        return _revokeReadAccess(accessor, account);
    }

    function setRegistration(string publicKey) public {
        registration[msg.sender] = publicKey;
        registered[msg.sender] = true;
    }

    function unRegister() public {
        delete registration[msg.sender];
        registered[msg.sender] = false;
    }

    function remove(bytes32 accessor) public {
        require(isOwner(accessor, msg.sender));

        delete data[accessor];
        claimed[accessor] = false;

        for (uint i = 0; i < members[accessor].accounts.length; i++) {
            address member = members[accessor].accounts[i];

            delete keys[accessor][member];
            // delete owners[accessor][member];
            // delete admins[accessor][member];
            // delete writers[accessor][member];
            // delete readers[accessor][member];
        }
        delete members[accessor];
    }

    // === GETTERS ===
    //
    function isOwner(bytes32 accessor, address account) public view returns(bool) {
        return members[accessor].owners[account] > 0;
    }

    function isAdmin(bytes32 accessor, address account) public view returns(bool) {
        return members[accessor].admins[account] > 0;
    }

    function canWrite(bytes32 accessor, address account) public view returns(bool) {
        return members[accessor].writers[account] > 0;
    }

    function canRead(bytes32 accessor, address account) public view returns(bool) {
        return members[accessor].readers[account] > 0;
    }

    function getKey(bytes32 accessor, address account) public view returns(bytes) {
        return keys[accessor][account];
    }

    function getMembers(bytes32 accessor) public view returns(address[]) {
        return members[accessor].accounts;
    }

    // === PRIVATE SETTERS ===
    //
    function _create(address account, bytes32 accessor, bytes encryptedData, bytes encryptedKey) private {
        _claim(account, accessor);
        _issueEncryptedKey(accessor, account, encryptedKey);
        _write(accessor, encryptedData);
    }

    function _claim(address account, bytes32 accessor) private {
        claimed[accessor] = true;
        _addOwner(accessor, account);
    }

    function _write(bytes32 accessor, bytes encryptedData) private {
        data[accessor] = encryptedData;
    }

    function _addOwner(bytes32 accessor, address account /*, bytes encryptedKey */) private returns(uint8) {
        if (isOwner(accessor, account)) {
            return members[accessor].owners[account];
        }
        // return members[accessor].owners[account] = _addAdmin(accessor, account, encryptedKey);
        return members[accessor].owners[account] = _addAdmin(accessor, account);
    }

    function _addAdmin(bytes32 accessor, address account /*, bytes encryptedKey */) private returns(uint8) {
        if (isAdmin(accessor, account)) {
            return members[accessor].admins[account];
        }
        // return members[accessor].admins[account] = _grantWriteAccess(accessor, account, encryptedKey);
        return members[accessor].admins[account] = _grantWriteAccess(accessor, account);
    }

    function _grantWriteAccess(bytes32 accessor, address account /*, bytes encryptedKey */) private returns(uint8) {
        if (canWrite(accessor, account)) {
            return members[accessor].writers[account];
        }
        // return members[accessor].writers[account] = _grantReadAccess(accessor, account, encryptedKey);
        return members[accessor].writers[account] = _grantReadAccess(accessor, account);
    }

    function _grantReadAccess(bytes32 accessor, address account /*, bytes encryptedKey */) private returns(uint8) {
        if (canRead(accessor, account)) {
            return members[accessor].readers[account];
        }
        // _issueEncryptedKey(accessor, account, encryptedKey);
        return members[accessor].readers[account] = _addMember(accessor, account);
    }

    function _issueEncryptedKey(bytes32 accessor, address account, bytes encryptedKey) private {
        keys[accessor][account] = encryptedKey;
    }

    function _removeOwner(bytes32 accessor, address account) private returns(uint8) {
        uint8 id = members[accessor].owners[account];
        if (id < 1) {
            return id;
        }
        delete members[accessor].owners[account];
        return id;
    }

    function _removeAdmin(bytes32 accessor, address account) private returns(uint8) {
        uint8 id = members[accessor].admins[account];
        if (id < 1) {
            return id;
        }
        delete members[accessor].admins[account];
        _removeOwner(accessor, account);
        return id;
    }

    function _revokeWriteAccess(bytes32 accessor, address account) private returns(uint8) {
        uint8 id = members[accessor].writers[account];
        if (id < 1) {
            return id;
        }
        delete members[accessor].writers[account];
        _removeAdmin(accessor, account);
        return id;
    }

    function _revokeReadAccess(
        bytes32 accessor,
        address account
        // bytes encryptedData,
        // bytes encryptedKey
    ) private returns(uint8) {
        // _write(accessor, encryptedData);
        // _issueEncryptedKey(accessor, msg.sender, encryptedKey);
        uint8 id = _removeMember(accessor, account);
        delete members[accessor].readers[account];
        _revokeWriteAccess(accessor, account);
        return id;
    }

    function _addMember(bytes32 accessor, address account) private returns(uint8) {
        return uint8(members[accessor].accounts.push(account));
    }

    function _removeMember(bytes32 accessor, address account) private returns(uint8) {
        uint8 index = id - 1;
        if (index >= members[accessor].accounts.length) return 0;

        MemberList storage m = members[accessor];
        uint8 id = m.readers[account];

        delete m.accounts[index];

        if (index > 0) {
            address lastAccount = m.accounts[m.accounts.length - 1];
            m.accounts[index] = lastAccount;
            _changeId(accessor, account, id);
        }

        m.accounts.length--;

        return id;
    }

    function _changeId(bytes32 accessor, address account, uint8 id) private {
        MemberList storage m = members[accessor];

        if (isOwner(accessor, account)) {
            m.owners[account] = id;
        }
        if (isAdmin(accessor, account)) {
            m.admins[account] = id;
        }
        if (canWrite(accessor, account)) {
            m.writers[account] = id;
        }
        if (canRead(accessor, account)) {
            m.readers[account] = id;
        }
    }
}
