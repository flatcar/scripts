# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1

DESCRIPTION="Amazon EC2 Elastic Network Adapter (ENA) kernel driver"
HOMEPAGE="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/enhanced-networking-ena.html"
SRC_URI="https://github.com/amzn/amzn-drivers/archive/ena_linux_${PV}.tar.gz -> ${P}-linux.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="+builtin"

BDEPEND="app-arch/unzip"
DEPEND="builtin? ( sys-kernel/coreos-sources:= )
	!!>${CATEGORY}/${PF}
	!!<${CATEGORY}/${PF}
"

S="${WORKDIR}/amzn-drivers-ena_linux_${PV}/kernel/linux/ena"

CONFIG_CHECK="PCI_MSI !CPU_BIG_ENDIAN DIMLIB"
DOCS=(
	README.rst
	RELEASENOTES.md
	ENA_Linux_Best_Practices.rst
)

pkg_setup() {
	if use builtin; then
		return
	fi
	linux-mod-r1_pkg_setup
}

src_compile() {
	if use builtin; then
		return
	fi
	local modlist=( ena=net )
	local modargs=( CONFIG_MODULE_SIG=n KERNEL_BUILD_DIR="${KV_OUT_DIR}" )
	linux-mod-r1_src_compile
}

src_install() {
	if use builtin; then
		sed -i \
		  -e 's|ENA_COM_PATH=.*|ENA_COM_PATH=ena_com|' \
		  -e 's|$(src)|$(srctree)/$(src)|' Makefile
		dodir /usr/src
		insinto /usr/src/"${PF}"
		doins -r "."

		insinto /usr/src/"${PF}"/ena_com
		doins -r "../common/ena_com/."

		return
	fi
	linux-mod-r1_src_install
}

pkg_postinst() {
	if use builtin; then
		mv ${EROOT}/usr/src/linux/drivers/net/ethernet/amazon/{ena,ena.orig}
		ln -s ../../../../../"${PF}" ${EROOT}/usr/src/linux/drivers/net/ethernet/amazon/ena
		return
	fi
	linux-mod-r1_pkg_postinst
}

pkg_postrm() {
	if use builtin; then
		rm -f ${EROOT}/usr/src/linux/drivers/net/ethernet/amazon/ena
		mv ${EROOT}/usr/src/linux/drivers/net/ethernet/amazon/{ena.orig,ena}
		return
	fi
	linux-mod-r1_pkg_postrm
}
