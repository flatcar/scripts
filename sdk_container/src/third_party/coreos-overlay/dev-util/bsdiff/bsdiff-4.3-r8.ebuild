# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic toolchain-funcs

DESCRIPTION="bsdiff: Binary Differencer using a suffix alg"
HOMEPAGE="https://www.daemonology.net/bsdiff/"
SRC_URI="https://www.daemonology.net/bsdiff/${P}.tar.gz"

SLOT="0"
LICENSE="BSD-2"
# Flatcar: enable arm64
KEYWORDS="~alpha amd64 ~arm arm64 hppa arm64 ~ia64 ~mips ppc sparc x86 ~amd64-linux ~x86-linux ~ppc-macos"

RDEPEND="app-arch/bzip2"

PATCHES=(
	"${FILESDIR}/${P}-CVE-2014-9862.patch"
	# Flatcar: Apply patch to change suffix sort to sais-lite, and
	# to fix heap overflow vulnerability CVE-2020-14315.
	"${FILESDIR}/${PV}_bsdiff-convert-to-sais-lite-suffix-sort.patch"
	"${FILESDIR}/${P}-CVE-2020-14315.patch"
)

src_compile() {
	doecho() {
		echo "$@"
		"$@"
	}
	append-lfs-flags
	# Flatcar: build including sais.c, which comes from 3rd-party patch
	# 4.3_bsdiff-convert-to-sais-lite-suffix-sort.patch.
	doecho $(tc-getCC) ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} -o bsdiff bsdiff.c sais.c -lbz2 || die "failed compiling bsdiff"
	doecho $(tc-getCC) ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} -o bspatch bspatch.c -lbz2 || die "failed compiling bspatch"
}

src_install() {
	dobin bs{diff,patch}
	doman bs{diff,patch}.1
}
