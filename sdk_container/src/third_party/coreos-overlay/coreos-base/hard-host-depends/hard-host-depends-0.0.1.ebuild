# Copyright (c) 2009 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="List of packages that are needed on the buildhost (meta package)"
HOMEPAGE="http://src.chromium.org"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64 x86"
IUSE=""

# Needed to run setup crossdev, run build scripts, and make a bootable image.
RDEPEND="${RDEPEND}
	app-arch/lzop
	app-arch/pigz
	app-admin/perl-cleaner
	app-admin/sudo
	sys-apps/less
	dev-embedded/u-boot-tools
	!arm64? ( sys-boot/syslinux )
	sys-devel/crossdev
	sys-fs/dosfstools
	"

# Host dependencies for building cross-compiled packages.
# TODO: chromeos-base/chromeos-installer
RDEPEND="${RDEPEND}
	acct-group/netperf
	acct-group/ntp
	acct-group/polkitd
	acct-user/netperf
	acct-user/ntp
	acct-user/polkitd
	>=app-arch/pbzip2-1.1.1-r1
	app-arch/rpm2targz
	app-arch/sharutils
	app-arch/unzip
	app-crypt/tpm2-tools
	app-eselect/eselect-iptables
	app-emulation/qemu
	app-text/asciidoc
	app-text/xmlto
	dev-build/gtk-doc-am
	dev-go/go-md2man
	dev-lang/go-bootstrap
	dev-lang/go
	dev-lang/nasm
	=dev-lang/python-3*
	dev-lang/swig
	dev-lang/tcl
	dev-lang/yasm
	dev-libs/dbus-glib
	>=dev-libs/glib-2.26.1
	dev-libs/libgcrypt
	dev-libs/libnl
	dev-libs/libpwquality
	dev-libs/libxslt
	dev-libs/libyaml
	dev-libs/luksmeta
	dev-libs/nspr
	dev-libs/protobuf
	dev-python/cachecontrol
	dev-python/distlib
	dev-python/distro
	dev-python/flit-core
	dev-python/gpep517
	dev-python/poetry-core
	dev-python/pyproject-hooks
	dev-python/resolvelib
	dev-python/rich
	dev-python/setuptools
	dev-python/truststore
	dev-python/typing-extensions
	dev-python/wheel
	dev-util/gdbus-codegen
	dev-util/gperf
	dev-util/patchutils
	>=dev-vcs/git-1.7.2
	net-libs/libtirpc
	amd64? ( net-misc/google-cloud-sdk )
	sys-apps/gptfdisk
	sys-apps/systemd
	sys-apps/usbutils
	sys-devel/bc
	sys-libs/nss-usrfiles
	virtual/udev
	"

# Host dependencies that create usernames/groups we need to pull over to target.
RDEPEND="${RDEPEND}
	sys-apps/dbus
	"

# Host dependencies that are needed by mod_image_for_test.
RDEPEND="${RDEPEND}
	sys-process/lsof
	"

# Useful utilities for developers.
RDEPEND="${RDEPEND}
	app-arch/zip
	app-containers/syft
	app-doc/eclass-manpages
	app-portage/gentoolkit
	app-portage/portage-utils
	app-editors/vim
	dev-util/perf
	sys-apps/pv
	app-shells/bash-completion
	"

# Host dependencies that are needed to create and sign images
# TODO:	sys-apps/mosys
# app-crypt/ccid is required for pcsc-lite daemon to work.
RDEPEND="${RDEPEND}
	sys-fs/squashfs-tools
	dev-libs/libp11
	dev-libs/opensc
	app-crypt/ccid
	"

# Host dependencies that are needed for delta_generator.
RDEPEND="${RDEPEND}
	coreos-base/update_engine
	"

# Host dependencies for python
RDEPEND="${RDEPEND}
	dev-python/docutils
	"

# Host dependencies to scp binaries from the binary component server
# TODO: chromeos-base/ssh-known-hosts
#	chromeos-base/ssh-root-dot-dir
RDEPEND="${RDEPEND}
	net-misc/openssh
	net-misc/wget
	"

# Host dependencies for building ISOs
RDEPEND="${RDEPEND}
	app-cdr/cdrtools
	"

# Uninstall these packages.
RDEPEND="${RDEPEND}
	!coreos-base/google-breakpad
	"
