pragma solidity ^0.4.8;

import "./UserStorage.sol";

contract PendingManager {

    // TYPES

    struct Transaction {
        address to;
        bytes data;
    }

    // struct for the status of a pending operation
    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
        uint index;
    }


    // FIELDS

    address userStorage;

    mapping (bytes32 => Transaction) public txs;

    // the ongoing operations
    mapping (bytes32 => PendingState) pendings;

    mapping (uint => bytes32) pendingsIndex;

    uint pendingCount = 1;


    // EVENTS

    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    event Done(bytes32 operation, bytes data);


    /// MODIFIERS

    // simple single-sig function modifier
    modifier onlyOwner {
        if (isOwner(msg.sender)) {
            _;
        }
    }

    // multi-sig function modifier: the operation must have an intrinsic hash in order
    // that later attempts can be realised as the same underlying operation and
    // thus count as confirmations
    modifier onlyManyOwners(bytes32 _operation, address _sender) {
        if (confirmAndCheck(_operation, _sender)) {
            _;
        }
    }


    // METHODS

    function init(address _userStorage) {
        userStorage = _userStorage;
    }

    function pendingsCount() constant returns (uint) {
        return pendingCount;
    }

    function pendingById(uint _id) constant returns (bytes32) {
        return pendingsIndex[_id];
    }

    function getPending(uint _id) constant returns (bytes32 index, bytes data, uint yetNeeded, uint ownersDone) {
        index = pendingsIndex[_id];
        data = getTxsData(index);
        yetNeeded = pendingYetNeeded(index);
        ownersDone = pendings[index].ownersDone;
        return (index, data, yetNeeded, ownersDone);
    }

    function getPendingByHash(bytes32 _hash) constant returns (bytes data, uint yetNeeded, uint ownersDone) {
        data = getTxsData(_hash);
        yetNeeded = pendingYetNeeded(_hash);
        ownersDone = pendings[_hash].ownersDone;
        return (data, yetNeeded, ownersDone);
    }

    function pendingYetNeeded(bytes32 _hash) constant returns (uint) {
        return pendings[_hash].yetNeeded;
    }

    function getTxsData(bytes32 _hash) constant returns (bytes) {
        return txs[_hash].data;
    }

    function addTx(bytes32 _r, bytes data, address to, address sender) {
        if (pendingCount > 20) {
            throw;
        }
        txs[_r].data = data;
        txs[_r].to = to;
        conf(_r, sender);
    }

    function confirm(bytes32 _h) returns (bool) {
        return conf(_h, msg.sender);
    }

    function conf(bytes32 _h, address sender) onlyManyOwners(_h, sender) returns (bool) {
        if (txs[_h].to != 0) {
            if (!txs[_h].to.call(txs[_h].data)) {
                throw;
            }
            delete txs[_h];
            return true;
        }
    }

    // revokes a prior confirmation of the given operation
    function revoke(bytes32 _operation) external {
        if (isOwner(msg.sender)) {
            uint ownerIndexBit = 2 ** UserStorage(userStorage).getMemberId(msg.sender);
            var pending = pendings[_operation];
            if (pending.ownersDone & ownerIndexBit > 0) {
                pending.yetNeeded++;
                pending.ownersDone -= ownerIndexBit;
                Revoke(msg.sender, _operation);
            }
        }
    }

    // gets an owner by 0-indexed position (using numOwners as the count)
    function getOwner(uint ownerIndex) external constant returns (address) {
        return UserStorage(userStorage).getMemberAddr(ownerIndex);
    }

    function isOwner(address _addr) constant returns (bool) {
        return UserStorage(userStorage).getCBE(_addr);
    }

    function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
        var pending = pendings[_operation];
        if (isOwner(_owner)) {
            // determine the bit to set for this owner
            uint ownerIndexBit = 2 ** UserStorage(userStorage).getMemberId(_owner);
            return !(pending.ownersDone & ownerIndexBit == 0);
        }
    }

    function clearPending() {
        uint length = pendingCount;
        for (uint i = 0; i < length; ++i) {
            if (pendingsIndex[i] != 0) {
                delete pendings[pendingsIndex[i]];
                delete pendingsIndex[i];
            }
        }
    }


    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation, address sender) internal returns (bool) {
        if (isOwner(sender)) {
            var pending = pendings[_operation];
            // if we're not yet working on this operation, switch over and reset the confirmation status
            if (pending.yetNeeded == 0) {
                // reset count of confirmations needed
                pending.yetNeeded = UserStorage(userStorage).required();
                // reset which owners have confirmed (none) - set our bitmap to 0
                pending.ownersDone = 0;
                pending.index = pendingCount;
                pendingCount++;
                pendingsIndex[pending.index] = _operation;
            }
            // determine the bit to set for this owner
            uint ownerIndexBit = 2 ** UserStorage(userStorage).getMemberId(sender);
            // make sure we (the message sender) haven't confirmed this operation previously
            if (pending.ownersDone & ownerIndexBit == 0) {
                Confirmation(msg.sender, _operation);
                // ok - check if count is enough to go ahead
                if (pending.yetNeeded <= 1) {
                    // enough confirmations: reset and run interior
                    Done(_operation, txs[_operation].data);
                    delete pendingsIndex[pendings[_operation].index];
                    removeOp(pendings[_operation].index);
                    delete pendings[_operation];
                    return true;
                } else {
                    // not enough: record that this owner in particular confirmed
                    pending.yetNeeded--;
                    pending.ownersDone |= ownerIndexBit;
                }
            }
        }
    }

    function removeOp(uint i) internal {
        if (i >= pendingCount) {
            return;
        }
        while (i < pendingCount - 1) {
            pendings[pendingsIndex[i + 1]].index = pendings[pendingsIndex[i]].index;
            pendingsIndex[i] = pendingsIndex[i + 1];
            i++;
        }
        pendingCount--;
    }

    function()
    {
        throw;
    }
}
