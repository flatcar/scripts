# Copyright 2044-2016 The Flatcar Maintainers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit coreos-kernel savedconfig systemd

DESCRIPTION="HyperV guest support daemons."
KEYWORDS="amd64 arm64"

src_compile() {
    # Build hv_vss_daemon, hv_kvp_daemon, hv_fcopy_daemon
    kmake tools/hv
}

src_install() {
    dobin "${S}/build/tools/hv/hv_fcopy_daemon"
    dobin "${S}/build/tools/hv/hv_kvp_daemon"
    dobin "${S}/build/tools/hv/hv_vss_daemon"

    systemd_dounit "${FILESDIR}/hv_fcopy_daemon.service"
    systemd_dounit "${FILESDIR}/hv_kvp_daemon.service"
    systemd_dounit "${FILESDIR}/hv_vss_daemon.service"

    systemd_enable_service "multi-user.target" "hv_fcopy_daemon.service"
    systemd_enable_service "multi-user.target" "hv_kvp_daemon.service"
    systemd_enable_service "multi-user.target" "hv_vss_daemon.service"
}
