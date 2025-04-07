`001-dracut-post-106.patch` is the merged upstream changes from v106 to current
main for some potentially important fixes and to provide a clean base for
`002-dracut-sysroot.patch`. This can be dropped when bumping to v107.

`002-dracut-sysroot.patch` is Chewi's new Dracut improvements, which allow it to
parse the ELF .note.dlopen dependency metadata used by JSON and reliably
determine dependencies across foreign architectures. They will hopefully be
merged in v108. See https://github.com/dracut-ng/dracut-ng/pull/1260.

`050-change-network-dep-iscsi.patch` is a Flatcar-specific dependency tweak to
use flatcar-network instead of network.
