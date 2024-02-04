// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAccountBackup {
    function checkIsBackup(address _currentAccount, address _nextAccount) external view returns (bool);
    function proposeBackup(address _backingUp, address _proposedAccount) external;
    function acceptBackup(address _backUpThisAddress) external;
}
