pragma solidity ^0.4.8;

import {PendingManager as Shareable} from "./PendingManager.sol";
import "./UserStorage.sol";

contract Managed {
    address userStorage;
    address shareable;

    event exec(bytes32 hash);

    modifier onlyAuthorized() {
        if (isAuthorized(msg.sender) || msg.sender == shareable) {
            _;
        }
    }

    modifier execute() {
        if (msg.sender != shareable) {
            bytes32 _r = sha3(msg.data, "signature");
            Shareable(shareable).addTx(_r, msg.data, this);
            exec(_r);
        }
        else {
            _;
        }
    }

    function isAuthorized(address key) returns (bool) {
        return UserStorage(userStorage).getCBE(key);
    }
}
