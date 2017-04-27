pragma solidity ^0.4.8;

contract UserStorage {
    // the number of owners that must confirm the same operation before it is run.
    uint public required = 1;

    mapping (uint => Member) public members;
    struct Member {
        address memberAddr;
        bytes32 hash;
        bool isCBE;
    }

    uint public userCount = 1;
    uint public adminCount = 0;
    uint ownersCount = 1;

    mapping (address => uint) userIndex;
    mapping (address => uint) public ownersIndex;

    // simple single-sig function modifier.
    modifier onlyOwner {
        if (isOwner(msg.sender)) {
            _;
        }
    }

    function isOwner(address _addr) constant returns (bool) {
        if (ownersIndex[_addr] != 0x0) {
            return true;
        }
        return false;
    }

    function UserStorage() {
        ownersIndex[msg.sender] = ownersCount;
        ownersCount++;
    }

    function setRequired(uint _required) onlyOwner() returns (bool) {
        if (_required > 0 && adminCount >= _required) {
            required = _required;
            return true;
        }
        return false;
    }

    function addOwner(address _owner) onlyOwner() returns (bool) {
        ownersIndex[_owner] = ownersCount;
        ownersCount++;
        return true;
    }

    function getOwner(address _owner) constant returns (bool) {
        if (ownersIndex[_owner] > 0) {
            return true;
        }
        return false;
    }

    function deleteOwner(address _owner) onlyOwner() returns (bool) {
        delete ownersIndex[_owner];
        return true;
    }

    function getCBEMembers() constant returns (address[] addresses, bytes32[] hashes) {
        addresses = new address[](adminCount);
        hashes = new bytes32[](adminCount);
        uint j = 0;
        for (uint i = 1; i < userCount; i++) {
            if (members[i].isCBE) {
                addresses[j] = members[i].memberAddr;
                hashes[j] = members[i].hash;
                j++;
            }
        }
        return (addresses, hashes);
    }

    function addMember(address _member, bool _isCBE) onlyOwner() returns (bool) {
        if (userIndex[_member] == uint(0x0)) {
            members[userCount] = Member(_member, 1, _isCBE);
            userIndex[_member] = userCount;
            userCount++;
            if (_isCBE) {
                setCBE(_member, _isCBE);
            }
            return true;
        }
        return false;
    }

    function setCBE(address _member, bool _isCBE) onlyOwner() returns (bool) {
        members[userIndex[_member]].isCBE = _isCBE;
        if (!_isCBE) {
            adminCount--;
            if (adminCount < required) {
                required--;
            }
        } else {
            adminCount++;
        }
        return true;
    }

    function setHashes(address _member, bytes32 _hash) onlyOwner() returns (bool) {
        members[userIndex[_member]].hash = _hash;
        return true;
    }

    function getHash(address _member) constant returns (bytes32) {
        return (members[userIndex[_member]].hash);
    }

    function deleteMember(uint _id) onlyOwner() returns (bool) {
        delete members[_id];
        return true;
    }

    function getMember(address _member) constant returns (address) {
        return members[userIndex[_member]].memberAddr;
    }

    function getMemberAddr(uint _id) constant returns (address) {
        return members[_id].memberAddr;
    }

    function getMemberId(address _member) constant returns (uint) {
        return userIndex[_member];
    }

    function getCBE(address _member) constant returns (bool) {
        return members[userIndex[_member]].isCBE;
    }

    function()
    {
        throw;
    }
}
