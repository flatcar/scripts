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

3. We build and install only a subset of binaries in the project.
   Namely, we skip all the daemon stuff that puts the logs in
   `/var/log/audit` and some tools that process those logs. Since
   audit logs are also written to journal, writing them to disk seems
   redundant, thus auditd and the tools seem to be unnecessary. This
   also reduces the final image size a bit.

4. Since we do not install the daemon, we don't do the permissions
   lockdown on some auditd files.
