// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable2Step} from "../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccountBackup} from "./AccountBackup.sol";

contract Ownable2StepWithBackup is Ownable2Step, AccountBackup {
    constructor(address _initalDefaultAdmin, address _initialBackup)
        Ownable(_msgSender())
        AccountBackup(_initialBackup, _initalDefaultAdmin, 0, 0)
    {}

    function transferOwnership(address newOwner) public override onlyOwner {
        if (checkIsBackup(owner(), newOwner)) {
            _transferOwnership(newOwner);
        } else {
            super.transferOwnership(newOwner);
        }
    }
}
