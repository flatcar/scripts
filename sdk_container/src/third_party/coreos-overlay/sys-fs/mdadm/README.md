This is a fork of Gentoo's sys-fs/mdadm package. The main reason of
having this fork is to carry Flatcar-specific patches for using
systemd.timer instead of cron.weekly.

There is also a minor change to build this package by default for
arm64 without needing an entry in accept_keywords file.
