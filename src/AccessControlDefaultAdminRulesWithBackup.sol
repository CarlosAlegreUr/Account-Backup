// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlDefaultAdminRules} from
    "../lib/openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {AccountBackup} from "./AccountBackup.sol";

/**
 * @title AccessControlDefaultAdminRulesPlusBackup
 * @author @CarlosAlegreUr
 * @notice This is how to combine the AccessControlDefaultAdminRules and AccountBackup contracts
 * to create a safer way to transfer the DEFAULT_ADMIN_ROLE.
 */
contract AccessControlDefaultAdminRulesWithBackup is AccessControlDefaultAdminRules, AccountBackup {
    constructor(uint48 _initDelay, address _initalDefaultAdmin, address _initialBackup)
        AccessControlDefaultAdminRules(_initDelay, _initalDefaultAdmin)
        AccountBackup(_initialBackup, _initalDefaultAdmin, 0, 0)
    {}

    /**
     * @dev Begins the DEFAULT_ADMIN_ROLE transfer to a new address, but if the new address
     * is the backup of the current addres which holds the DEFAULT_ADMIN_ROLE, then the transfer
     * will happen atomatically.
     *
     * @notice This is to avoid the admin race problem if the key(s) of the DEFAULT_ADMIN_ROLE is compromised.
     * The admin race problem is when a key gets compromised and both, original owner(s) and the attacker who
     * got the key try to front-run each other to set the `DEFAULT_ADMIN_ROLE` to a new address just one of them
     * controls.
     *
     * @param newAdmin is the address who will be able to accept de DEFAULT_ADMIN_ROLE
     */
    function beginDefaultAdminTransfer(address newAdmin) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (checkIsBackup(defaultAdmin(), newAdmin)) {
            _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        } else {
            super.beginDefaultAdminTransfer(newAdmin);
        }
    }
}
