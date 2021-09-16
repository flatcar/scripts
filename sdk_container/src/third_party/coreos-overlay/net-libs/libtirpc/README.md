This is a fork of gentoo package. We have it on overlay because:

- We change the NETCONFIG macro value from `"/etc/netconfig"` to
  `"/usr/share/tirpc/netconfig"`.

- We update the installation of the netconfig accordingly to the
  previous point.

- We include a patch that fixes a DOS vulnerability (comes from
  https://git.linux-nfs.org/?p=steved/libtirpc.git;a=commit;h=86529758570cef4c73fb9b9c4104fdc510f701ed).
