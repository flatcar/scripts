Modifications done in this fork:

- Disable user sessions. We don't need them in Flatcar. At some point
  Gentoo dropped the dedicated USE flag for it and enables user
  sessions with systemd USE flag.

- Drop the dependency on sec-policy/selinux-dbus which is brought by
  the selinux USE flag. We enable the flag because we still want DBus
  to be selinux-aware, but for some reason we didn't want to pull in
  the `sec-policy/selinux-dbus` package. We may want to revisit this
  with our SELinux work.

- Drop /etc/machine-id generation. We do it elsewhere (bootengine?).

- Mark it as stable for amd64 and arm64.
