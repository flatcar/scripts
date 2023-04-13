This directory gets symlinked from `${ROOT}/etc/portage/patches`. It
may contain patches for packages that will be applied during the
prepare phase. Basic usage of this directory is more or less as
follows: if you have a patch for e.g. the sys-devel/gcc package then
create a `sys-devel/gcc` directory and drop the patch there. The patch
needs to end with either `.patch` or `.diff` to be picked up. Ideally
the patches should be prefixed with a number (`git format-patch`
style) so the order of patch application is obvious. Also remember
that you can't patch ebuild files that way.

For more details about user patches, please refer to Gentoo Wiki page
about it:

https://wiki.gentoo.org/wiki//etc/portage/patches
