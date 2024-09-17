# Copyright 2044-2016 The Flatcar Maintainers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit coreos-kernel savedconfig systemd

DESCRIPTION="HyperV guest support daemons."
KEYWORDS="amd64 arm64"

if [[ "${PV}" == 9999 ]]; then
    KEYWORDS="~amd64 ~arm64"
fi

src_compile() {
    # Build hv_vss_daemon, hv_kvp_daemon, hv_fcopy_daemon
    kmake tools/hv
}

src_install() {
    HV_DAEMONS=(hv_vss_daemon hv_kvp_daemon hv_fcopy_daemon hv_fcopy_uio_daemon)
    for HV_DAEMON in "$HV_DAEMONS[@]"
    do
        if [ -f "${S}/build/tools/hv/${HV_DAEMON}" ]; then
            dobin "${S}/build/tools/hv/${HV_DAEMON}"
            systemd_dounit "${FILESDIR}/${HV_DAEMON}.service"
            systemd_enable_service "multi-user.target" "${HV_DAEMON}.service"
        fi
    done
}
