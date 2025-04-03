This is a fork of gentoo package. We have it on overlay because:

- We change the NETCONFIG macro value from `"/etc/netconfig"` to
  `"/usr/share/tirpc/netconfig"`.

- We update the installation of the netconfig accordingly to the
  previous point.
