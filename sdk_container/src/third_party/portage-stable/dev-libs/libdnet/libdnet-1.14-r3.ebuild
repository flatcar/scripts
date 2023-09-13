# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

AT_M4DIR="config"

inherit autotools

DESCRIPTION="simplified, portable interface to several low-level networking routines"
HOMEPAGE="https://github.com/ofalk/libdnet"
SRC_URI="https://github.com/ofalk/${PN}/archive/${P}.tar.gz"
S="${WORKDIR}/${PN}-${P}"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm ~arm64 ~hppa ~ia64 ~mips ppc ppc64 ~riscv sparc x86"
IUSE="test"
REQUIRED_USE=""
RESTRICT="!test? ( test )"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND="
"

DOCS=( README.md THANKS )

PATCHES=(
	"${FILESDIR}/${PN}-1.14-ndisc.patch"
	"${FILESDIR}/${PN}-1.14-strlcpy.patch"
)

src_prepare() {
	default

	sed -i \
		-e 's/libcheck.a/libcheck.so/g' \
		-e 's|AM_CONFIG_HEADER|AC_CONFIG_HEADERS|g' \
		configure.ac || die
	sed -i \
		-e 's|-L$libdir ||g' \
		dnet-config.in || die
	sed -i \
		-e '/^SUBDIRS/s|python||g' \
		Makefile.am || die

	eautoreconf
}

src_configure() {
	# Install into OEM, don't bother with a sbin directory.
	econf \
		--prefix=/oem \
		--sbindir=/oem/bin \
		--disable-static \
		--without-python
}

src_install() {
	default

	find "${ED}" -name '*.la' -delete || die
}
