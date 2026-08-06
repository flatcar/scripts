The patch `0001-Add-account-locking.patch` adds some locking
behavior. Upstream didn't want it:
https://github.com/linux-pam/linux-pam/issues/261.

Possibly it should be dropped in favor of `chage -E 0`, as mentioned
in the issue.

The patch `0002-pam_userdb-fix-password-comparison-timing-leak.patch`
can be dropped when 1.7.3 or 1.8 is released.
