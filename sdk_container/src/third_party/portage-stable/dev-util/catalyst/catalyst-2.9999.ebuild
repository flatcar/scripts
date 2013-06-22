# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/catalyst/catalyst-2.9999.ebuild,v 1.11 2013/06/16 14:58:39 dolsen Exp $

EAPI="5"

PYTHON_COMPAT=( python{2_6,2_7} )

inherit distutils-r1 git-2

DESCRIPTION="Release metatool used for creating releases based on Gentoo Linux."
HOMEPAGE="http://www.gentoo.org/proj/en/releng/catalyst/"
EGIT_REPO_URI="git://git.overlays.gentoo.org/proj/catalyst.git"
EGIT_MASTER="master"
EGIT_BRANCH="3.0"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
IUSE="ccache doc kernel_linux"

KEYWORDS=""

DEPEND="app-text/asciidoc
	>=dev-python/snakeoil-0.5.2"

RDEPEND="app-arch/lbzip2
	app-crypt/shash
	virtual/cdrtools
	ccache? ( dev-util/ccache )
	ia64? ( sys-fs/dosfstools )
	kernel_linux? ( app-misc/zisofs-tools >=sys-fs/squashfs-tools-2.1 )"

python_prepare_all() {
	python_export_best
	echo VERSION="${PV}" "${PYTHON}" setup.py set_version
	VERSION="${PV}" "${PYTHON}" setup.py set_version
}

python_compile_all() {
	# build the man pages and docs
	emake
}

python_install_all(){
	distutils-r1_python_install_all
	if use doc; then
		dodoc files/HOWTO.html files/docbook-xsl.css
	fi
}
