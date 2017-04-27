pragma solidity ^0.4.8;

import "./UserStorage.sol";

contract PendingManager {
    // TYPES

    struct Transaction {
        address to;
        bytes data;
    }

    // status of a pending operation
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
    uint pendingCount;

    // EVENTS

    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    event Done(bytes data);

    // MODIFIERS

    // simple single-sig function modifier
    modifier onlyOwner {
        if (isOwner(msg.sender)) {
            _;
        }
    }

    // multi-sig function modifier: the operation must have an intrinsic hash in order
    // that later attempts can be realised as the same underlying operation and
    // thus count as confirmations
    modifier onlyManyOwners(bytes32 _operation) {
        if (confirmAndCheck(_operation)) {
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

    function pendingYetNeeded(bytes32 _hash) constant returns (uint) {
        return pendings[_hash].yetNeeded;
    }

    function getTxsType(bytes32 _hash) returns (uint) {
        return uint(txs[_hash].op);
    }

    function getTxsData(bytes32 _hash) constant returns (bytes) {
        return txs[_hash].data;
    }

    function addTx(bytes32 _r, bytes data, address to) {
        if (pendingCount > 20) {
            throw;
        }
        txs[_r].data = data;
        txs[_r].op = op;
        txs[_r].to = to;
        confirm(_r);
    }

    function confirm(bytes32 _h) onlyManyOwners(_h) returns (bool) {
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
            uint index = UserStorage(userStorage).getMemberId(_owner);
            // make sure they're an owner
            if (index == 0) return false;

            // determine the bit to set for this owner.
            uint ownerIndexBit = 2 ** index;
            return !(pending.ownersDone & ownerIndexBit == 0);
        }
    }

    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation) internal returns (bool) {
        if (isOwner(tx.origin)) {
            var pending = pendings[_operation];
            // if we're not yet working on this operation, switch over and reset the confirmation status
            if (pending.yetNeeded == 0) {
                // reset count of confirmations needed
                pending.yetNeeded = UserStorage(userStorage).required();
                // reset which owners have confirmed (none) - set our bitmap to 0
                pending.ownersDone = 0;
                pending.index = pendingCount++;
                pendingsIndex[pending.index] = _operation;
            }
            // determine the bit to set for this owner.
            uint ownerIndexBit = 2 ** UserStorage(userStorage).getMemberId(tx.origin);
            // make sure we (the message sender) haven't confirmed this operation previously.
            if (pending.ownersDone & ownerIndexBit == 0) {
                Confirmation(msg.sender, _operation);
                // ok - check if count is enough to go ahead.
                if (pending.yetNeeded <= 1) {
                    // enough confirmations: reset and run interior.
                    Done(txs[_operation].data);
                    delete pendingsIndex[pendings[_operation].index];
                    removeOp(pendings[_operation].index);
                    delete pendings[_operation];
                    return true;
                }
                else {
                    // not enough: record that this owner in particular confirmed.
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

    function() {
        throw;
    }
}
