# Copyright 2025 The Flatcar Maintainers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit coreos-kernel systemd

DESCRIPTION="HyperV guest support daemons"
KEYWORDS="amd64 arm64"

src_configure() {
	:
}

src_compile() {
	emake \
		-C "${KV_DIR}/tools/hv" \
		ARCH="${CHOST%%-*}" \
		CROSS_COMPILE="${CHOST}-" \
		OUTPUT="${S}/" \
		V=1
}

src_install() {
	local HV_DAEMON
	for HV_DAEMON in hv_{kvp,vss}_daemon $(usex !arm64 hv_fcopy_uio_daemon ""); do
		dobin "${HV_DAEMON}"
		systemd_dounit "${FILESDIR}/${HV_DAEMON}.service"
		systemd_enable_service "multi-user.target" "${HV_DAEMON}.service"
	done
}
