# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/qscintilla/qscintilla-2.7.ebuild,v 1.2 2012/12/25 02:32:53 pesa Exp $

EAPI=5

inherit qt4-r2

MY_P=QScintilla-gpl-${PV}

DESCRIPTION="A Qt port of Neil Hodgson's Scintilla C++ editor class"
HOMEPAGE="http://www.riverbankcomputing.co.uk/software/qscintilla/intro"
SRC_URI="mirror://sourceforge/pyqt/${MY_P}.tar.gz"

LICENSE="|| ( GPL-2 GPL-3 )"
SLOT="0/9"
KEYWORDS="~alpha ~amd64 ~ia64 ~ppc ~ppc64 ~sparc ~x86"
IUSE="doc python"

DEPEND="
	x11-libs/qt-core:4
	x11-libs/qt-gui:4
"
RDEPEND="${DEPEND}"
PDEPEND="python? ( ~dev-python/qscintilla-python-${PV} )"

S=${WORKDIR}/${MY_P}

PATCHES=(
	"${FILESDIR}/${PN}-2.6.2-designer.patch"
)

src_unpack() {
	qt4-r2_src_unpack

	# Sub-slot sanity check
	local subslot=${SLOT#*/}
	local version=$(sed -nre 's:.*VERSION\s*=\s*([0-9\.]+):\1:p' "${S}"/Qt4Qt5/qscintilla.pro)
	local major=${version%%.*}
	if [[ ${subslot} != ${major} ]]; then
		eerror
		eerror "Ebuild sub-slot (${subslot}) does not match QScintilla major version (${major})"
		eerror "Please update SLOT variable as follows:"
		eerror "    SLOT=\"${SLOT%%/*}/${major}\""
		eerror
		die "sub-slot sanity check failed"
	fi
}

src_configure() {
	pushd Qt4Qt5 > /dev/null
	einfo "Configuration of qscintilla"
	eqmake4 qscintilla.pro
	popd > /dev/null

	pushd designer-Qt4 > /dev/null
	einfo "Configuration of designer plugin"
	eqmake4 designer.pro
	popd > /dev/null
}

src_compile() {
	pushd Qt4Qt5 > /dev/null
	einfo "Building of qscintilla"
	emake
	popd > /dev/null

	pushd designer-Qt4 > /dev/null
	einfo "Building of designer plugin"
	emake
	popd > /dev/null
}

src_install() {
	pushd Qt4Qt5 > /dev/null
	einfo "Installation of qscintilla"
	emake INSTALL_ROOT="${D}" install
	popd > /dev/null

	pushd designer-Qt4 > /dev/null
	einfo "Installation of designer plugin"
	emake INSTALL_ROOT="${D}" install
	popd > /dev/null

	dodoc NEWS

	if use doc; then
		dohtml doc/html-Qt4Qt5/*
		insinto /usr/share/doc/${PF}
		doins -r doc/Scintilla
	fi
}
