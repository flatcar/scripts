# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Flatcar: Based on tini-0.18.0.ebuild from commit
# d6c89a5caedbe5cae98142ebb99974b41177aedd in gentoo repo (see
# https://gitweb.gentoo.org/repo/gentoo.git/plain/sys-process/tini/tini-0.18.0.ebuild?id=d6c89a5caedbe5cae98142ebb99974b41177aedd).

EAPI=7

# Flatcar: We provide our autotools-based build system to avoid build
# dependency on cmake. So the settings are hardcoded in the build
# system - we want static binary and a non-minimal build.
inherit autotools

GIT_COMMIT=de40ad007797e0dcd8b7126f27bb87401d224240
DESCRIPTION="A tiny but valid init for containers"
HOMEPAGE="https://github.com/krallin/tini"
SRC_URI="https://github.com/krallin/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
# Flatcar: We don't mark arm64 as "testing".
KEYWORDS="amd64 arm64"
# Flatcar: No IUSE on args or on static - it's hardcoded in the build
# system replacement.

src_prepare() {
	# Flatcar: We don't use cmake, so all the code handling cmake
	# stuff is dropped. Autotools provide the standard configure
	# && make && make install build protocol, which Gentoo handles
	# out of the box.
	for file in configure.ac Makefile.am src/Makefile.am; do
		cp "${FILESDIR}/automake/${file}" "${S}/${file}"
	done
	eapply_user

	export tini_VERSION_MAJOR=$(ver_cut 1)
	export tini_VERSION_MINOR=$(ver_cut 2)
	export tini_VERSION_PATCH=$(ver_cut 3)
	export tini_VERSION_GIT=${GIT_COMMIT}
	eautoreconf
}
