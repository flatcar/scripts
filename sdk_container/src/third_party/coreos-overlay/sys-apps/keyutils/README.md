We keep this package in overlay, because we install the keyutils
config file in /usr instead of /etc, and then establish some symlinks
during installation and with systemd's tmpfiles.d utility.
