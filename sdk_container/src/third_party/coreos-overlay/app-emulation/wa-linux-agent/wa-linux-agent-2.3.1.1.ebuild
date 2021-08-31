# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Windows Azure Linux Agent"
HOMEPAGE="https://github.com/Azure/WALinuxAgent"
KEYWORDS="amd64 arm64"
SRC_URI="${HOMEPAGE}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

RDEPEND="
dev-lang/python-oem
dev-python/distro-oem
"

PATCHES=(
	"${FILESDIR}/0001-Support-flatcar.patch"
)

S="${WORKDIR}/WALinuxAgent-${PV}"

src_install() {
	into "/usr/share/oem"
	dobin "${S}/bin/waagent"

	# When updating python-oem, remember to update the path below.
	insinto "/usr/share/oem/python/$(get_libdir)/python3.6/site-packages"
	doins -r "${S}/azurelinuxagent/"

	insinto "/usr/share/oem"
	doins "${FILESDIR}/waagent.conf"
}
