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
	app-crypt/azure-keyvault-pkcs11
	app-crypt/p11-kit
	app-crypt/sbsigntools
	app-emulation/open-vmdk
	app-emulation/virt-firmware
	app-eselect/eselect-python
	app-misc/jq
	app-shells/bash-completion
	app-text/mandoc
	coreos-base/hard-host-depends
	coreos-base/coreos-sb-keys
	dev-libs/gobject-introspection-common
	dev-python/setuptools
	dev-python/six
	dev-util/catalyst
	dev-util/pahole
	dev-util/patchelf
	net-dns/bind
	>=net-dns/dnsmasq-2.72[dhcp,ipv6]
	net-libs/rpcsvc-proto
	net-misc/curl
	sys-apps/debianutils
	sys-apps/iproute2
	amd64? ( sys-apps/iucode_tool )
	sys-apps/seismograph
	sys-boot/grub
	sys-firmware/edk2-bin
	sys-fs/btrfs-progs
	sys-fs/cryptsetup
        sys-fs/erofs-utils
	dev-perl/Parse-Yapp
	dev-util/pkgcheck
"

# Must match the build-time dependencies listed in selinux-policy-2.eclass
DEPEND="${DEPEND}
	!arm64? (
		>=sys-apps/checkpolicy-2.0.21
		>=sys-apps/policycoreutils-2.0.82
	)
	sys-devel/m4"

DEPEND="${DEPEND}
	sys-apps/bubblewrap
	>=dev-python/gpep517-15
"

# These packages are pulled indirectly during the multi-stage SDK
# build, but our package automation can't catch them. Pull them
# explicitly.
DEPEND="${DEPEND}
	app-alternatives/sh
	app-editors/nano
	virtual/dev-manager
	virtual/libc
	virtual/openssh
	virtual/package-manager
	virtual/pager
	virtual/service-manager
	virtual/ssh
"

RDEPEND="${DEPEND}"
