This is a fork of gentoo's `sys-process/audit` package. The main
reasons for having our fork seem to be:

1. We have our own audit rules (see files in `files/rules.d`
   directory).

  - These seem to be mostly similar to what gentoo provides, but split
    into several files and they have an additional rule for SELinux
    events.

  - We also install it in a different place and place symlinks with
    systemd's tmpfiles functionality.

2. We install a systemd service that loads our rules at startup.

3. We add a `daemon` use flag that gates a build of `auditd` binary
   and some more tools. This flag seems to be unused, which results in
   the daemon and tools not being built. The role of auditd is to
   write audit records to disk, and both ausearch and aureport utilize
   those written logs. Since audit logs are also written to journal,
   writing them to disk seems redundant, thus auditd and the tools
   seem to be unnecessary. This also reduces the final image size a
   bit.

4. We don't do the permissions lockdown on some auditd files for some
   reason. It's either related that we don't build auditd in practice
   or it's about our own audit rules.
