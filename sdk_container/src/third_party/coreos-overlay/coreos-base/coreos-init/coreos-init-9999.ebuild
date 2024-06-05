# Copyright (c) 2013 The CoreOS Authors. All rights reserved.
# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="flatcar/init"
CROS_WORKON_LOCALNAME="init"
CROS_WORKON_REPO="https://github.com"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
else
	CROS_WORKON_COMMIT="db06907d621459ed488ca13031852357b59b24ec" # tormath1/sysext
	KEYWORDS="amd64 arm arm64 x86"
fi

PYTHON_COMPAT=( python3_{9..11} )

inherit cros-workon systemd python-any-r1

DESCRIPTION="Init scripts for CoreOS"
HOMEPAGE="http://www.coreos.com/"
SRC_URI=""

LICENSE="BSD"
SLOT="0/${PVR}"
IUSE="test"

# Daemons we enable here must installed during build/install in addition to
# during runtime so the systemd unit enable step works.
DEPEND="
	net-misc/openssh
	net-nds/rpcbind
	!coreos-base/oem-service
	test? ( ${PYTHON_DEPS} )
	"
RDEPEND="${DEPEND}
	app-admin/logrotate
	sys-block/parted
	sys-apps/gptfdisk
	>=sys-apps/systemd-207-r5
	>=coreos-base/coreos-cloudinit-0.1.2-r5
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
