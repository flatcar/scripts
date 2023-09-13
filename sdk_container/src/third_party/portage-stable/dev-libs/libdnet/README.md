This is a fork of gentoo package. It's a dependency of the
open-vm-tools which is installed in the oem partition. We have it in
overlay, because:

- We drop python stuff from the package.
- We change the prefix and sbindir.
