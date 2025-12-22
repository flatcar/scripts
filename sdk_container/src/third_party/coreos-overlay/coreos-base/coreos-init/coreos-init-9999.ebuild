# Copyright (c) 2013 The CoreOS Authors. All rights reserved.
# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..11} )
inherit systemd python-any-r1

DESCRIPTION="Init scripts for Flatcar"
HOMEPAGE="https://github.com/flatcar/init"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/flatcar/init.git"
	inherit git-r3
else
	EGIT_VERSION="860090d932a0bcdf71a73619f270845a06b64af0" # flatcar-master
	SRC_URI="https://github.com/flatcar/init/archive/${EGIT_VERSION}.tar.gz -> ${PN}-${EGIT_VERSION}.tar.gz"
	S="${WORKDIR}/init-${EGIT_VERSION}"
	KEYWORDS="amd64 arm arm64 x86"
fi

LICENSE="BSD"
SLOT="0/${PVR}"
IUSE="test"
RESTRICT="!test? ( test )"

# Daemons we enable here must installed during build/install in addition to
# during runtime so the systemd unit enable step works.
DEPEND="
	net-misc/openssh
	net-nds/rpcbind
"
RDEPEND="${DEPEND}
	app-admin/logrotate
	sys-block/parted
	sys-apps/gptfdisk
	>=sys-apps/systemd-207-r5
	>=coreos-base/coreos-cloudinit-0.1.2-r5
"
BDEPEND="
	test? ( ${PYTHON_DEPS} )
"

src_install() {
	emake DESTDIR="${D}" install

	# Enable some services that aren't enabled elsewhere.
	systemd_enable_service rpcbind.target rpcbind.service

	# Create compatibility symlinks in case /usr/lib64/ instead of /usr/lib/ was used
	local compat
	for compat in modules flatcar coreos ; do
		dosym "../lib/${compat}" "/usr/lib64/${compat}"
	done
}
