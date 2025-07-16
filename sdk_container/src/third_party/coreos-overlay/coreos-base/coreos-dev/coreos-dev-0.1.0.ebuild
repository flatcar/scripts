# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="CoreOS developer images and containers (meta package)"
HOMEPAGE="http://coreos.com"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm arm64 x86"

# The dependencies here are meant to capture "all the packages
# developers want to use for development, test, or debug".  This
# category is meant to include all developer use cases, including
# software test and debug, performance tuning, hardware validation,
# and debugging failures.
RDEPEND="
	app-portage/gentoolkit
	dev-python/urllib3
	coreos-base/coreos
	coreos-base/emerge-gitclone
	dev-debug/gdb
	dev-debug/strace
	dev-lang/python
	dev-util/pahole
	net-analyzer/netperf
	net-analyzer/traceroute
	net-dialup/minicom
	net-misc/iperf
	net-misc/iputils
	net-misc/openssh
	net-misc/rsync
	sys-apps/coreutils
	sys-apps/diffutils
	sys-apps/file
	sys-apps/findutils
	sys-apps/i2c-tools
	sys-apps/kbd
	sys-apps/less
	sys-apps/portage
	sys-apps/smartmontools
	sys-apps/which
	sys-devel/gcc
	sys-fs/inotify-tools
	sys-fs/lvm2
	sys-fs/squashfs-tools
	sys-process/procps
	sys-process/psmisc
	"
