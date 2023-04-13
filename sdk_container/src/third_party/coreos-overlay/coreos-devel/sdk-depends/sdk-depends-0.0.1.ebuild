# Copyright 2013 The CoreOS Authors
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

DESCRIPTION="Meta ebuild for everything that needs to be in the SDK."
HOMEPAGE="http://coreos.com/docs/sdk/"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE=""

DEPEND="
	app-admin/sudo
	app-admin/updateservicectl
	app-arch/pbzip2
	app-crypt/efitools
	app-crypt/sbsigntools
	app-emulation/acbuild
	app-emulation/actool
	app-emulation/open-vmdk
	app-misc/jq
	app-shells/bash-completion
	coreos-base/hard-host-depends
	coreos-base/coreos-sb-keys
	coreos-devel/fero-client
	dev-libs/gobject-introspection
	dev-python/setuptools
	dev-util/boost-build
	dev-util/catalyst
	dev-util/checkbashisms
	dev-util/dwarves
	dev-util/patchelf
	dev-vcs/repo
	net-dns/bind-tools
	>=net-dns/dnsmasq-2.72[dhcp,ipv6]
	net-libs/rpcsvc-proto
	net-misc/curl
	sys-apps/debianutils
	sys-apps/iproute2
	amd64? ( sys-apps/iucode_tool )
	sys-apps/seismograph
	sys-boot/grub
	sys-boot/shim
	sys-firmware/edk2-ovmf
	sys-fs/btrfs-progs
	sys-fs/cryptsetup
	dev-perl/Parse-Yapp
	"

# Must match the build-time dependencies listed in selinux-policy-2.eclass
DEPEND="${DEPEND}
	!arm64? (
		>=sys-apps/checkpolicy-2.0.21
		>=sys-apps/policycoreutils-2.0.82
	)
	sys-devel/m4"

# Required by dev-lang/spidermonkey-1.8.5
DEPEND="${DEPEND}
	sys-devel/autoconf:2.1"

RDEPEND="${DEPEND}"
