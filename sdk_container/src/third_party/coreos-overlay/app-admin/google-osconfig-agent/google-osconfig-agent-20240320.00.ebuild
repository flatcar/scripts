#
# Copyright 2023 Google LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

EAPI=7

inherit go-module systemd

DESCRIPTION="Google OS Config Agent"
HOMEPAGE="https://github.com/GoogleCloudPlatform/osconfig"

SRC_URI="https://github.com/GoogleCloudPlatform/osconfig/archive/${PV}.tar.gz -> ${P}.tar.gz"
SRC_URI+=" ${P}-deps.tar.xz"

LICENSE="Apache-2.0 BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

S="${WORKDIR}/osconfig-${PV}"

src_compile() {
	export GOTRACEBACK="crash"
	GO=$(tc-getGO)
	export GO
	# These compilation flags are from packaging/debian/rules,
	# packaging/google-osconfig-agent.spec, and
	# packaging/googet/google-osconfig-agent.goospec in the osconfig source tree.
	CGO_ENABLED=0 ${GO} build -ldflags="-s -w -X main.version=${PV}" \
		-mod=readonly -o google_osconfig_agent || die
}

src_install() {
	dobin google_osconfig_agent
	systemd_dounit google-osconfig-agent.service
	systemd_enable_service multi-user.target google-osconfig-agent.service

	systemd_dounit "${FILESDIR}"/google-osconfig-init.service
	systemd_enable_service google-osconfig-agent.service google-osconfig-init.service

	exeinto /usr/share/google
	doexe "${FILESDIR}"/no_ssh.sh
}
