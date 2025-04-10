# Copyright 2014-2025 The Flatcar Maintainers
# Distributed under the terms of the GNU General Public License v2

EAPI=8
COREOS_SOURCE_REVISION=""
inherit systemd

DESCRIPTION="Hyper-V guest support daemons"
HOMEPAGE="http://www.kernel.org"
S="${WORKDIR}"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64"

DEPEND="=sys-kernel/coreos-sources-${PV}${COREOS_SOURCE_REVISION:--r0}"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
fi

src_compile() {
	emake \
		-C "${ESYSROOT}/usr/src/linux-${PV/_rc/-rc}-coreos${COREOS_SOURCE_REVISION}/tools/hv" \
		ARCH="${CHOST%%-*}" \
		CROSS_COMPILE="${CHOST}-" \
		OUTPUT="${S}/"
}

src_install() {
	local HV_DAEMON HV_DAEMONS=( hv_{fcopy,kvp,vss}_daemon )
	use arm64 || HV_DAEMONS+=( hv_fcopy_uio_daemon )

	for HV_DAEMON in "${HV_DAEMONS[@]}"; do
		dobin "${HV_DAEMON}"
		systemd_dounit "${FILESDIR}/${HV_DAEMON}.service"
		systemd_enable_service "multi-user.target" "${HV_DAEMON}.service"
	done
}
