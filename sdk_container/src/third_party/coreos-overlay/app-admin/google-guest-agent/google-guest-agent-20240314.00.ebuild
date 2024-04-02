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

# Flatcar: inherit coreos-go-depend
COREOS_GO_VERSION=go1.21
inherit coreos-go-depend go-module systemd

DESCRIPTION="Google Guest Agent"
HOMEPAGE="https://github.com/GoogleCloudPlatform/guest-agent"

SRC_URI="https://github.com/GoogleCloudPlatform/guest-agent/archive/${PV}.tar.gz -> ${P}.tar.gz"
# Flatcar: explicitly reference mirror
SRC_URI+=" https://commondatastorage.googleapis.com/cos-localmirror/distfiles/${P}-deps.tar.xz"

LICENSE="Apache-2.0 BSD ZLIB"
SLOT="0"
KEYWORDS="*"
IUSE=""
RDEPEND="!app-admin/compute-image-packages
	>=app-admin/oslogin-20231004.00
"

S=${WORKDIR}/guest-agent-${PV}

PATCHES=(
	"${FILESDIR}/20231016.00-homedir-gid.patch"
	"${FILESDIR}/20231016.00-create-hostkey-and-instanceID-dirs.patch"
)

# Flatcar: export GO variables
src_prepare() {
	go_export
	default
}

src_compile() {
	export GOTRACEBACK="crash"
	pushd google_guest_agent || die
	# Flatcar: switch to EGO
	CGO_ENABLED=0 ${EGO} build -ldflags="-s -w -X main.version=${PV}" \
		-mod=readonly || die
	popd || die
	pushd google_metadata_script_runner || die
	# Flatcar: switch to EGO
	CGO_ENABLED=0 ${EGO} build -ldflags="-s -w -X main.version=${PV}" \
		-mod=readonly || die
	popd || die
}

src_install() {
	dobin google_guest_agent/google_guest_agent
	dobin google_metadata_script_runner/google_metadata_script_runner
	systemd_dounit google-guest-agent.service
	systemd_dounit google-startup-scripts.service
	systemd_dounit google-shutdown-scripts.service
	systemd_enable_service multi-user.target google-guest-agent.service
	systemd_enable_service multi-user.target google-startup-scripts.service
	systemd_enable_service multi-user.target google-shutdown-scripts.service

	# Backports the get_metadata_value script from compute-image-packages.
	# We have users that still rely on this script, so we need to continue
	# to install it.
	exeinto /usr/share/google/
	newexe "${FILESDIR}/get_metadata_value" get_metadata_value

	# Install COS specific configuration
	insinto /etc/default
	newins "${FILESDIR}/20201102-instance_configs.cfg.distro" instance_configs.cfg.distro
}
