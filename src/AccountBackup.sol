// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AccountBackup {
    mapping(address /* I have a role */ => address /* This is my backup */) private backupAddressOf;
    mapping(address /*Im backup of*/ => address /*This address*/) private isBackupOf;

    mapping(address /*Role holder*/ => address /*Backup*/) private backupProposals;
    mapping(bytes32 /*Backup proposal*/ => uint256 /*StartedAt*/) private backupProposalsDeadlines;

    uint256 private delay = 1 days;
    uint256 private acceptaneLimit = 1 days;

    modifier afterDelay(address backingUp) {
        bytes32 backupId = keccak256(abi.encode(msg.sender, backingUp));
        require(
            block.timestamp > backupProposalsDeadlines[backupId]
                && block.timestamp < backupProposalsDeadlines[backupId] + acceptaneLimit,
            "Delay not passed"
        );
        _;
    }

    function checkIsBackup(address _currentAccount, address _nextAccount) public view returns (bool) {
        return (backupAddressOf[_currentAccount] == _nextAccount) ? true : false;
    }

    function proposeBackup(address _backingUp, address _proposedAccount) public {
        backupProposals[_backingUp] = _proposedAccount;
        backupProposalsDeadlines[keccak256(abi.encode(_backingUp, _proposedAccount))] = block.timestamp + delay;
    }

    function acceptBackup(address _backUpThisAddress) public afterDelay(_backUpThisAddress) {
        require(msg.sender == backupProposals[_backUpThisAddress], "You can't accept this role.");
        backupAddressOf[_backUpThisAddress] = msg.sender;
        isBackupOf[msg.sender] = _backUpThisAddress;
    }
}
