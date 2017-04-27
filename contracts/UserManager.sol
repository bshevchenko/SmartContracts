pragma solidity ^0.4.8;

import "./Managed.sol";

contract UserManager is Managed {
    event cbeUpdate(address key);
    event setReq(uint required);

    function init(address _userStorage, address _shareable) returns (bool) {
        if (userStorage != 0x0) {
            return false;
        }
        userStorage = _userStorage;
        shareable = _shareable;
        UserStorage(userStorage).addMember(msg.sender, true);
        return true;
    }

    function addKey(address key) execute {
        if (!UserStorage(userStorage).getCBE(key) // make sure that the key being submitted isn't already CBE
            && (UserStorage(userStorage).addMember(key, true) || UserStorage(userStorage).setCBE(key, true))) {
            // new CBE member was created or old member became CBE
            cbeUpdate(key);
        }
    }

    function revokeKey(address key) execute {
        if (UserStorage(userStorage).getCBE(key)) { // make sure that the key being revoked is exist and is CBE
            UserStorage(userStorage).setCBE(key, false);
            cbeUpdate(key);
        }
    }

    function createMemberIfNotExist(address key) internal {
        UserStorage(userStorage).addMember(key, false);
    }

    function setMemberHash(address key, bytes32 _hash) onlyAuthorized returns (bool) {
        createMemberIfNotExist(key);
        UserStorage(userStorage).setHashes(key, _hash);
        return true;
    }

    function setOwnHash(bytes32 _hash) returns (bool) {
        createMemberIfNotExist(msg.sender);
        UserStorage(userStorage).setHashes(msg.sender, _hash);
        return true;
    }

    function getMemberHash(address key) constant returns (bytes32) {
        return UserStorage(userStorage).getHash(key);
    }

    function required() constant returns (uint) {
        return UserStorage(userStorage).required();
    }

    function setRequired(uint _required) execute returns (bool) {
        setReq(_required);
        return UserStorage(userStorage).setRequired(_required);
    }

    function()
    {
        throw;
    }
}
