This is a fork of gentoo's sys-process/tini package. The sole reason
that this package is in coreos-overlay and not in portage-stable is to
get rid of the build dependency on cmake, which we do not provide. The
build system is replaced with a small autotools setup (see
[files/automake](files/automake)).
