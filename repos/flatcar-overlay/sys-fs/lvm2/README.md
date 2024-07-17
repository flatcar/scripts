We keep this package in overlay, because we carry one extra patch for
the unit generator. It was posted upstream and remains
unacknowledged. We could try sending the patch to gentoo, so we can
bring this package back to portage-stable.

The lvm2-activation(-early).service was triggered multiple times which
if done too quickly leads to a failure like this:

systemd[1]: Finished Activation of LVM2 logical volumes.
systemd[1]: lvm2-activation-early.service: Start request repeated too quickly.
systemd[1]: lvm2-activation-early.service: Failed with result 'start-limit-hit'.

Set RemainAfterExit=yes as done for the other oneshot services to
prevent the unit from running multiple times in a row and hitting the
restart limit.



We also patch the configure script to use the correct path for systemd
util directory.
