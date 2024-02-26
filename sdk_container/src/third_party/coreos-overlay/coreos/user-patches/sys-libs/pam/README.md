The patch adds some locking behavior. Upstream didn't want it:
https://github.com/linux-pam/linux-pam/issues/261.

Possibly it should be dropped in favor of `chage -E 0`, as mentioned
in the issue.
