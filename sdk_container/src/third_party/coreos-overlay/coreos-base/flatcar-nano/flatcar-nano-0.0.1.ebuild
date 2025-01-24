# Copyright (c) The Flatcar Maintainers
# Distributed under the terms of the GNU General Public License v2


# To build, run
#   emerge-amd64-usr --newuse --changed-use --buildpkg flatcar-nano cryptsetup lvm2 curl nghttp2 grub shim util-linux baselayout
#   ./build_image --base_pkg=coreos-base/flatcar-nano --base_sysext="" --replace
#   ./image_to_vm.sh --from=../build/images/amd64-usr/latest --board=amd64-usr --image_compression_formats none
#
#    { emerge-amd64-usr   ; echo "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"; ./build_image --base_pkg=coreos-base/flatcar-nano --base_sysext="" --replace; } 2>&1 | tee log
#
# NOTE: flatcar-nano uses different USE flags to be extra lean.
# See profiles/coreos/base/package.use.force for details.
# Core packages need a rebuild on order for this to work (hence the --[...]use flags)
#
#
# Current status
# - It builds (see above) and boots.
#   Needs a rebuild of most packages because of reduced USE flags (see profiles/coreos/base/package.use.force, flatcar-nano).
#   Trying to build it with "build_packages" will destroy the containerised build env (baselayout overwrites /etc/shadow w/ empty file).
# - Probably more packages could be removed. Bash is in there b/c dracut claims it needs Bash.
#
# Next steps
# - Manual testing, e.g. try to add image to a Kubernetes cluster using sysext.


EAPI=7

DESCRIPTION="Flatcar Nano image(meta package)"
HOMEPAGE="http://flatcar.org"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="selinux"

# t-lo 2025-01-24
# coreos-base/coreos doesn't have this which I think is weird.
BDEPEND="
    sys-boot/shim
    sys-boot/grub
"

RDEPEND=">=sys-apps/baselayout-3.0.0"

# Optionally enable SELinux for dbus and systemd (but always install packages and pull in the SELinux policy for containers)
RDEPEND="${RDEPEND}
	sys-apps/dbus[selinux?]
	sys-apps/systemd[selinux?]
	"

# Only applicable or available on amd64
RDEPEND="${RDEPEND}
	amd64? (
		app-emulation/xenserver-pv-version
		app-emulation/xenstore
	)"

# Removed 
#	app-admin/etcd-wrapper
#	app-admin/flannel-wrapper
#	app-admin/locksmith
#	app-admin/mayday
#	app-admin/sdnotify-proxy
#	app-admin/sudo
#	app-admin/toolbox
#	app-alternatives/awk
#	app-arch/gzip
#	app-arch/bzip2
#	app-arch/lbzip2
#	app-arch/lz4
#	app-arch/pigz
#	app-arch/xz-utils
#	app-arch/zstd
#	app-arch/tar
#	app-arch/unzip
#	app-arch/zip
#	app-arch/ncompress
#	app-crypt/adcli
#	app-editors/vim
#	app-containers/cri-tools
#   app-misc/jq
#	app-misc/pax-utils
#	app-shells/bash
#	coreos-base/update-ssh-keys
#	dev-db/etcdctl
#	dev-debug/strace
#	dev-libs/libsodium
#	dev-libs/openssl
#	dev-util/bpftool
#	dev-util/bsdiff
#	dev-vcs/git
#	net-analyzer/openbsd-netcat
#	net-analyzer/tcpdump
#	net-analyzer/traceroute
#	net-fs/nfs-utils
#	net-fs/cifs-utils
#	net-misc/curl
#	net-misc/rsync
#	net-misc/socat
#	net-misc/wget
#	net-misc/whois
#	sys-apps/acl
#	sys-apps/attr
#	sys-apps/coreutils
#	sys-apps/diffutils
#	sys-apps/ethtool
#	sys-apps/findutils
#	sys-apps/grep
#	sys-apps/less
#	sys-apps/lshw
#	sys-apps/net-tools
#	sys-apps/sed
#	sys-apps/usbutils
#	sys-apps/which
#	sys-auth/realmd
#	sys-auth/sssd
#	sys-devel/gettext
#	sys-fs/lsscsi
#	sys-fs/quota
#	sys-libs/glibc
#	sys-process/lsof
#	sys-process/procps

RDEPEND="${RDEPEND}
	app-crypt/clevis
	app-crypt/gnupg
	app-crypt/go-tspi
	app-crypt/tpmpolicy
	app-emulation/qemu-guest-agent
	app-misc/ca-certificates
	coreos-base/afterburn
	coreos-base/coreos-cloudinit
	coreos-base/coreos-init
	coreos-base/misc-files
	coreos-base/update_engine
	coreos-base/ue-rs
	net-dns/bind
	net-firewall/conntrack-tools
	net-firewall/ebtables
	net-firewall/ipset
	net-firewall/iptables
	net-firewall/nftables
	net-misc/bridge-utils
	net-misc/iputils
	net-misc/ntp
	net-vpn/wireguard-tools
	sec-policy/selinux-base
	sec-policy/selinux-base-policy
	sec-policy/selinux-container
	sec-policy/selinux-dbus
	sec-policy/selinux-policykit
	sec-policy/selinux-unconfined
	sys-apps/azure-vm-utils
	sys-apps/checkpolicy
	sys-apps/dbus
	sys-apps/gptfdisk
	sys-apps/ignition
	sys-apps/iproute2
	sys-apps/kexec-tools
	sys-apps/keyutils
	sys-apps/nvme-cli
	sys-apps/pciutils
	sys-apps/policycoreutils
	sys-apps/seismograph
	sys-apps/semodule-utils
	sys-apps/shadow
	sys-apps/util-linux
	sys-apps/zram-generator
	sys-block/open-iscsi
	sys-block/parted
	sys-boot/efibootmgr
	sys-boot/mokutil
	sys-cluster/ipvsadm
	sys-fs/btrfs-progs
	sys-fs/cryptsetup
	sys-fs/dosfstools
	sys-fs/e2fsprogs
	sys-fs/lvm2
	sys-fs/mdadm
	sys-fs/multipath-tools
	sys-fs/xfsprogs
	sys-kernel/coreos-firmware
	sys-kernel/coreos-kernel
	sys-libs/nss-usrfiles
	sys-libs/timezone-data
	sys-power/acpid
	x11-drivers/nvidia-drivers
"

# OEM specific bits that need to go in USR
RDEPEND+="
	amd64? (
		sys-auth/google-oslogin
	)
"
