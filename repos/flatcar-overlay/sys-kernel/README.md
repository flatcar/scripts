# Fatcar Container Linux kernel packages

The kernel is provided in three parts: coreos-sources, coreos-modules,
and coreos-kernel.

coreos-sources is a traditional Gentoo kernel source ebuild, which
installs to ${ROOT}/usr/src/linux-${PV}-coreos${COREOS_SOURCE_REVISION}.

coreos-modules uses the installed sources to build the kernel modules.
The kernel config is searched for in the files directory based
on the ebuild version and revision. For example version 3.12.4-r2:
 - amd64_defconfig-3.12.4-r2
 - amd64_defconfig-3.12.4
 - amd64_defconfig-3.12
 - amd64_defconfig

This is combined with a cross-architecture common configuration file, searched
for using the same rules - for example:
 - commonconfig-3.12.4-r2
 - commonconfig-3.12.4
 - commonconfig-3.12
 - commonconfig

coreos-kernel uses the installed sources and coreos-modules to build the
kernel image and initramfs. Many of its build dependencies are copied into
the initramfs by dracut, and several of these are significant enough that we
want to rebuild coreos-kernel whenever they change. Such packages set their
sub-slot to their ${PVR}, and then coreos-kernel DEPENDs on them using a
slot operator (":=") to force a rebuild whenever their sub-slot changes.

Currently our dracut based initramfs (bootengine) gets built directly into
the kernel image. The reason for this screwy scheme never came to pass and
should be fixed eventually. The current grub bootloader already includes
logic for initrds but the old configure_bootloaders and coreos-postinst
scripts need to be updated in order to support existing installs.

The coreos-firmware package is a magic version of the upstream
linux-firmware ebuild which scans the modules installed by coreos-modules
and only installs files modules declare as required.

# Keep kernel, kernel headers, and perf aligned

When updating the kernel to a new major release please make sure to also update
[the kernel headers](https://github.com/flatcar/portage-stable/tree/main/sys-kernel/linux-headers)
and
[perf](https://github.com/flatcar/portage-stable/tree/main/dev-util/perf)
to the same major version.
