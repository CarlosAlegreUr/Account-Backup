This repo solves (minimizes significantly) the problem of:

# WHAT IF YOUR MULTI-SIG (or wallet) GETS LEAKED DURIG A 2-TX OR DELAYED ROLE/ADMIN TRANSFER PROCESS ⁉️⁉️ ⚠️

The problem is the following: Imagine the account you use for some kind of role on your smart contract system (whether admin or other) gets compromised, for example with a leak of the keys. Then you would need to transfer the role to another account as soon as posible.

But, what if your system is using [AccessControlDefaultAdminRules](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/extensions/AccessControlDefaultAdminRules.sol) by OpenZepelin and now you have to wait for a period of time to safely transfer the role to another account?

This creates essentially a money race between the attacker who got the leaked signature and the true owners to see who can spend more gas front-running the other to change the admin succesfully.

The attacker might want to change the `DEFAULT_ADMIN_ROLE` but then team could cancel the process indeed.
Anyway they attacker might just keep trying. Effectively if you have less funds than the actor who got the leaked keys you lost the control. And the cost of this attack is the cost the attacker might find reasonable to spend to get the control of the system.

It is true that delayed transfers make the attack more expensive but, there are cheaper ways to mitigate this and if you are a small protocol it easily could be worth it for competing bigger agents to spend some money to "get rid of competitors".

Thus here I introduce the idea of a backup-admin of 2tx process transfer with a time delay should be added if desiring to change the backup-admin.

function proposeBackup()
function acceptBackup() [after time delay]

Now if attacker tries to change the admin, valid owners of the account can change to the back-up admin which they are suposed to
have control of.

And even if attacker tries to set a new future back-up admin, this has a delay so valid users
can just change to back-up damin which its private keys have not been compromised.

Now this creates the quesiton... what if the back-up also gets leaked?!?
Well, we can cheaply implement this mechanism recuresivelly with mappings and make it a new 
security requirement for protocols: how many back-up accounts you have?

mapping(address => address) _addressToBackup
mapping(address => address) _addressToIsBackupOf

So if, even if the back-up gets leaked, you can just can create as many back-ups for the back-up as you want.

Notice contracts like `Ownable2Step` can also benefit from this extension.

Now if in Onwable2Step the owner signature gets leaked, you can just 1tx transfer to the backup, but previously 2 step tx had to be done to confirm backup is a valid desired user so it applies the solution while keeping the 2tx essence.

With this method the cost of solving the problem if the attack is ever feasable is reduced significantly as there are no race conditions and you jut need to send a cheap 1tx and an acceptance tx with the back-up account.

Of course if signature gets leaked and the last backup to that leak is still not set-up then you are fucked. But if not then the rest of the time 99.99% of it you are safe. Before you were unsafe all the time. And by default in the constructor you can initialize 1 back-up if tou want so you already start with 2 protection agains leaked keys. Both should be compromised at the same
time and you not having a 3rd backup ready to actually be fucked.
