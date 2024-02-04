// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IAccountBackup} from "./IAccountBackup.sol";
import {Context} from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";

/**
 * @title AccountBackup
 * @author @CarlosAlegreUr
 * @notice This contract is to be used as a base contract to add backup accounts functionality to any contract.
 *
 * Its main purpose is to be used to manage transfers of ownership in `Ownable2Step` or
 * `AccessControlDefaultAdminRules` contracts from OpenZeppelin.
 *
 * But it could be used to assure safer transfers of important unique roles in any contract that
 * requires 2-tx processes, a delay (or both) for the transfers.
 */
contract AccountBackup is IAccountBackup, Context {
    mapping(address /* I have a role */ => address /* This is my backup */) private backupAddressOf;
    mapping(address /*Im the backup of*/ => address /*This address*/) private isBackupOf;

    mapping(address /*Role holder*/ => address /*Proposed backup*/) private backupProposals;
    mapping(bytes32 /*Backup proposal*/ => uint256 /*StartedAt timestampt*/) private backupProposalsDeadlines;

    // Delay to prevent corrupted address to quicikly propose malicious backups and start an admin race problem
    uint48 private acceptanceDelay;
    // Delay to prevent indefinite proposals
    uint48 private acceptaneLimitAfterDelay;

    uint48 private constant DEFAULT_DELAY = 5 days;

    /**
     * @notice If no delay is set, it will be set to DEFAULT_DELAY.
     * @notice The bakcup created on construction does not require 2-tx acceptance process.
     */
    constructor(
        address _initialRoleHolder,
        address _initialBackup,
        uint48 _acceptanceDelay,
        uint48 _acceptanceLimitAfterDelay
    ) {
        require(_initialRoleHolder != _initialBackup, "Initial role holder and backup can't be the same");
        require(_initialBackup != address(0), "Backups can't be 0 address");

        backupAddressOf[_initialRoleHolder] = _initialBackup;
        isBackupOf[_initialBackup] = _initialRoleHolder;
        acceptanceDelay = _acceptanceDelay > 0 ? _acceptanceDelay : DEFAULT_DELAY;
        acceptaneLimitAfterDelay = _acceptanceLimitAfterDelay > 0 ? _acceptanceLimitAfterDelay : DEFAULT_DELAY;
    }

    /**
     * @notice This modifier checks if:
     *
     * - Delay to prevent race admin problem has passed.
     * - Deadline to accept the backup role has not passed. The deadline must be set
     * to not have pending proposals forever. (e.g. UserA is proposed but never acceptes, because of that
     * UserB is proposed as new backup and UserB accepts, but UserA if it ever wants to, without a deadline,
     * could accept it too)
     *
     * @param backingUp The address that the caller is trying to be the backup of.
     */
    modifier acceptedOnTime(address backingUp) {
        bytes32 backupId = keccak256(abi.encode(_msgSender(), backingUp));
        require(
            block.timestamp >= backupProposalsDeadlines[backupId]
                && block.timestamp <= backupProposalsDeadlines[backupId] + acceptaneLimitAfterDelay,
            "Delay not passed"
        );
        _;
    }

    // ============ Backup Checker ============

    /**
     * @dev See {IAccountBackup-checkIsBackup}.
     */
    function checkIsBackup(address _currentAccount, address _nextAccount) public view virtual returns (bool) {
        return (backupAddressOf[_currentAccount] == _nextAccount) ? true : false;
    }

    // ============ Backup management ============

    /**
     * @dev See {IAccountBackup-proposeBackup}.
     *
     * @notice To create a 2nd backup, you need to call this function with the current backup.
     * Generally, to create a N-th backup, you need to call this function with the (N-1)-th backup.
     */
    function proposeBackup(address _backingUp, address _proposedAccount) public virtual {
        require(_backingUp == _msgSender(), "You can't propose a backup for someone else");
        require(_backingUp != _proposedAccount, "Account and backup can't be the same");
        require(_proposedAccount != address(0), "Backups can't be 0 address");

        backupProposals[_backingUp] = _proposedAccount;
        backupProposalsDeadlines[keccak256(abi.encode(_backingUp, _proposedAccount))] =
            block.timestamp + acceptaneLimitAfterDelay;
    }

    /**
     * @dev See {IAccountBackup-acceptBackup}.
     *
     * @notice The only way to accept must be that the backup account accepts itself to proof accesibility.
     */
    function acceptBackup(address _backUpThisAddress) public virtual acceptedOnTime(_backUpThisAddress) {
        require(_msgSender() == backupProposals[_backUpThisAddress], "You can't accept this role.");

        backupAddressOf[_backUpThisAddress] = _msgSender();
        isBackupOf[_msgSender()] = _backUpThisAddress;
    }

    // ============ Delays management ============

    /**
     * @dev Don't forget to add an onlyOwner or onlyRole modifier to this function in your contract
     * otherwise anyone could change the acceptance delay.
     *
     * @param _newDelay The new delay to prevent corrupted address to quicikly propose malicious backups.
     */
    function changeAcceptanceDelay(uint48 _newDelay) public virtual {
        // @note In the future this might need to get more flexible. Like allow to reduce the acceptance delay
        // but only take place once an `acceptanceDelay` has passed to prevent instant changes to a 0 delay which
        // corrupted accounts could use.
        require(_newDelay > acceptanceDelay);
        acceptanceDelay = _newDelay;
    }

    /**
     * @dev Don't forget to add an onlyOwner or onlyRole modifier to this function in your contract
     * otherwise anyone could change the acceptance limit.
     *
     * @param _newLimit The new limit to accept a backup proposal after the delay has passed.
     */
    function changeAcceptanceLimitAfterDelay(uint48 _newLimit) public virtual {
        acceptaneLimitAfterDelay = _newLimit;
    }
}
