# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="CoreOS (meta package)"
HOMEPAGE="http://coreos.com"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm arm64 x86"
IUSE="selinux"


################################################################################
#
# READ THIS BEFORE ADDING PACKAGES TO THIS EBUILD!
#
################################################################################
#
# Every coreos dependency (along with its dependencies) is included in the
# release image -- more packages contribute to longer build times, a larger
# image, slower and bigger auto-updates, increased security risks, etc. Consider
# the following before adding a new package:
#
# 1. Does the package really need to be part of the release image?
#
# Some packages can be included only in the developer or test images, i.e., the
# chromeos-dev or chromeos-test ebuilds. If the package will eventually be used
# in the release but it's still under development, consider adding it to
# chromeos-dev initially until it's ready for production.
#
# 2. Why is the package a direct dependency of the chromeos ebuild?
#
# It makes sense for some packages to be included as a direct dependency of the
# chromeos ebuild but for most it doesn't. The package should be added as a
# direct dependency of the ebuilds for all packages that actually use it -- in
# time, this ensures correct builds and allows easier cleanup of obsolete
# packages. For example, if a utility will be invoked by the session manager,
# its package should be added as a dependency in the chromeos-login ebuild. Or
# if the package adds a daemon that will be started through an upstart job, it
# should be added as a dependency in the chromeos-init ebuild. If the package
# really needs to be a direct dependency of the chromeos ebuild, consider adding
# a comment why the package is needed and how it's used.
#
# 3. Are all default package features and dependent packages needed?
#
# The release image should include only packages and features that are needed in
# the production system. Often packages pull in features and additional packages
# that are never used. Review these and consider pruning them (e.g., through USE
# flags).
#
# 4. What is the impact on the image size?
#
# Before adding a package, evaluate the impact on the image size. If the package
# and its dependencies increase the image size significantly, consider
# alternative packages or approaches.
#
# 5. Is the package needed on all targets?
#
# If the package is needed only on some target boards, consider making it
# conditional through USE flags in the board overlays.
#
################################################################################

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

# sys-devel/gettext: it embeds 'envsubst' binary which is useful for simple file templating.
RDEPEND="${RDEPEND}
	app-admin/etcd-wrapper
	app-admin/flannel-wrapper
	app-admin/locksmith
	app-admin/mayday
	app-admin/sdnotify-proxy
	app-admin/sudo
	app-admin/toolbox
	app-arch/gzip
	app-arch/bzip2
	app-arch/lbzip2
	app-arch/lz4
	app-arch/pigz
	app-arch/xz-utils
	app-arch/zstd
	app-arch/tar
	app-arch/torcx
	app-arch/unzip
	app-arch/zip
	app-arch/ncompress
	app-crypt/adcli
	app-crypt/gnupg
	app-crypt/go-tspi
	app-crypt/tpmpolicy
	app-editors/vim
	app-emulation/actool
	app-emulation/cri-tools
	app-misc/ca-certificates
	app-misc/jq
	app-misc/pax-utils
	app-shells/bash
	coreos-base/afterburn
	coreos-base/coreos-cloudinit
	coreos-base/coreos-init
	coreos-base/misc-files
	coreos-base/update-ssh-keys
	coreos-base/update_engine
	dev-db/etcdctl
	dev-libs/libsodium
	dev-libs/openssl
	dev-util/bpftool
	dev-util/bsdiff
	dev-util/strace
	dev-vcs/git
	net-analyzer/nmap
	net-analyzer/tcpdump
	net-analyzer/traceroute
	net-dns/bind-tools
	net-firewall/conntrack-tools
	net-firewall/ebtables
	net-firewall/ipset
	net-firewall/iptables
	net-firewall/nftables
	net-fs/nfs-utils
	net-fs/cifs-utils
	net-misc/bridge-utils
	net-misc/curl
	net-misc/iputils
	net-misc/ntp
	net-misc/rsync
	net-misc/socat
	net-misc/wget
	net-misc/whois
	net-vpn/wireguard-tools
	sec-policy/selinux-virt
	sec-policy/selinux-base
	sec-policy/selinux-base-policy
	sec-policy/selinux-unconfined
	sys-apps/acl
	sys-apps/attr
	sys-apps/coreutils
	sys-apps/checkpolicy
	sys-apps/dbus
	sys-apps/diffutils
	sys-apps/ethtool
	sys-apps/findutils
	sys-apps/gawk
	sys-apps/gptfdisk
	sys-apps/grep
	sys-apps/ignition
	sys-apps/iproute2
	sys-apps/kexec-tools
	sys-apps/keyutils
	sys-apps/less
	sys-apps/lshw
	sys-apps/net-tools
	sys-apps/nvme-cli
	sys-apps/pciutils
	sys-apps/policycoreutils
	sys-apps/sed
	sys-apps/seismograph
	sys-apps/semodule-utils
	sys-apps/shadow
	sys-apps/usbutils
	sys-apps/util-linux
	sys-apps/which
	sys-auth/realmd
	sys-auth/sssd
	sys-block/open-iscsi
	sys-block/parted
	sys-boot/efibootmgr
	sys-cluster/ipvsadm
	sys-devel/gettext
	sys-fs/btrfs-progs
	sys-fs/cryptsetup
	sys-fs/dosfstools
	sys-fs/e2fsprogs
	sys-fs/lsscsi
	sys-fs/lvm2
	sys-fs/mdadm
	sys-fs/multipath-tools
	sys-fs/quota
	sys-fs/xfsprogs
	sys-kernel/coreos-firmware
	sys-kernel/coreos-kernel
	sys-libs/glibc
	sys-libs/nss-usrfiles
	sys-libs/timezone-data
	sys-power/acpid
	sys-process/lsof
	sys-process/procps
	x11-drivers/nvidia-metadata
"

# OEM specific bits that need to go in USR
RDEPEND+="
	amd64? (
		app-emulation/qemu-guest-agent
		sys-auth/google-oslogin
	)
"
