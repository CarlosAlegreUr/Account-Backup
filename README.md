This repo solves (minimizes significantly) the problem of:

# WHAT IF YOUR ACCOUNT KEY(S) GETS LEAKED DURIG A 2-TX OR DELAYED UNIQUE ROLE/ADMIN TRANSFER PROCESS ⁉️ ⚠️

Imagine the account you use for some kind of unique role (only 1 address must hold it) on your smart contract system (whether admin or other) gets compromised, for example with a leak of the keys. Then you would need to transfer the role to another account as soon as posible, preferably immediately.

If you are using the classic `Ownable` solution you will just have to front-run the attacker and transfer the ownership quciker than him to another account you own.

But, what if your system is using [AccessControlDefaultAdminRules](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/extensions/AccessControlDefaultAdminRules.sol) by OpenZepelin? 

This creates essentially a race to set the new admin or unique role between the attacker who got the leaked key(s) and the true owner(s) to see who can spend more gas front-running the other to change the admin succesfully.

The attacker would need to init the transfer process and wait a delay to accept it hoping you wont cancel the operation in the meanwhile. So in practice the only thing the legit owner needs to do is to keep front-running the attacker canceling its change role proposals until all users are aware of the battle and move their funds to a save place. Actually the attacker can see this, and, in systems where there are special settings only modifyable by an admin, the attacker can complicate the
defense strategy by trying to modify those settings at the same time it tries to get the ownership to its own wallet, thys making the defense strategy more complex and expensive to nullify until all users are safe.

Effectively if you don't have enough funds to do this, you lost the control of your system and some or all users will be affected.

Thus here I introduce the idea of a `backup-address` for 2tx or delayed unique role/admin transfers processes. So, if you ever find yourself in this situation you will only need to front-run the attacker once and with 1tx making the defense mechanism way much more cheap.

## Backup-Addresses

A backup address is an address which a user holding a unique role can pass its role to without having to pass trhough the 2tx process or a time delay. This backup addresses must be owned by the same user which holds the role of course.

So now if your main account gets compromised you can just transfer it to the backup account in 1 tx.

Example on how [AccountBackup](./src/AccountBackup.sol) is used with `AccessControlDefaultAdminRules`:
[AccessControlDefaultAdminRulesWithBackup.sol](./src/AccessControlDefaultAdminRulesWithBackup.sol)

```solidity
  function beginDefaultAdminTransfer(address newAdmin) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (checkIsBackup(defaultAdmin(), newAdmin)) {
            _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        } else {
            super.beginDefaultAdminTransfer(newAdmin);
        }
    }
```

This alone won't prevent the attacker from creating this racing problem because he could always just use some `changeBackup()` account tx in the attack and thus creating again a the race problem.

So on top of this, changing a backup address requires a delay so the attacker can't just change the backup address and
then start the front-running defense race. If the attacker tries to change the backup then he will have to wait X time delay, and during that time delay you just need to send 1 successful tx to transfer the role to the backup.

## But what if the backup also gets compromised? 🤔

Well, we can cheaply implement backups for the backups if we desire with mappings and make it a new 
security requirement for protocols that implement this kind of unique roles handling to ask this question: how many back-up accounts do you have?

[AccountBackup.sol](./src/AccountBackup.sol) also handles this recursive backing up.

So if, even if the back-up account gets leaked, you can just have prepared as many back-ups for the back-ups as you want.

> 📘 **Note** ℹ️: This can also be used in [Ownable2Step](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol), which would require the legit admin to just safely use 1tx instead of 2 while the attacker would require 2tx. Still the attacker can front-run but it would become harder to do so. Plus the setting of the 
> backup account requires by default 2tx to be set so it doesnt contracdict the 2 step moto of `Ownable2Step`.
