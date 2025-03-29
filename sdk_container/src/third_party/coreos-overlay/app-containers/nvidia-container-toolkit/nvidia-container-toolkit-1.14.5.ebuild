# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGO_PN="github.com/NVIDIA/${PN}"

inherit coreos-go-depend

DESCRIPTION="NVIDIA container runtime toolkit"
HOMEPAGE="https://github.com/NVIDIA/nvidia-container-toolkit"
SRC_URI="https://github.com/NVIDIA/${PN}/archive/v${PV/_rc/-rc.}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"

DEPEND=""
RDEPEND="${DEPEND}
	sys-libs/libnvidia-container:=
"
BDEPEND=""

src_compile() {
	go_export
	emake binaries
}

src_install() {
	dobin nvidia-container-runtime{-hook,.cdi,} nvidia-ctk
	insinto "/etc/nvidia-container-runtime/"
	doins "${FILESDIR}/config.toml"
}
