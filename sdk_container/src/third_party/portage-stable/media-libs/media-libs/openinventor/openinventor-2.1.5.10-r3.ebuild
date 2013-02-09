# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/openinventor/openinventor-2.1.5.10-r3.ebuild,v 1.13 2013/01/28 02:46:49 mattst88 Exp $

EAPI=2
inherit eutils flag-o-matic multilib toolchain-funcs versionator

MY_PV=$(replace_version_separator 3 '-')
MY_PN=inventor

DESCRIPTION="SGI OpenInventor Toolkit and Utilities"
HOMEPAGE="http://oss.sgi.com/projects/inventor/"
SRC_URI="ftp://oss.sgi.com/projects/${MY_PN}/download/${MY_PN}-${MY_PV}.src.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 sparc x86"
IUSE=""

RDEPEND="
	|| (
		media-libs/mesa[motif]
		( media-libs/mesa x11-libs/libGLw ) )
	>=x11-libs/motif-2.3:0
	>=media-libs/freetype-2.0
	media-fonts/corefonts
	virtual/glu
	virtual/jpeg"
DEPEND="${RDEPEND}
	dev-util/byacc"

S=${WORKDIR}/${MY_PN}

src_prepare() {
	# ordinary yacc fails
	epatch "${FILESDIR}"/use-byacc.patch
	# support for amd64, sparc and alpha
	epatch "${FILESDIR}"/support-archs.patch
	epatch "${FILESDIR}"/support-sparc.patch
	# freetype2 wasn't enabled by default
	epatch "${FILESDIR}"/freetype2-activate.patch
	# extra #include statement necessary for freetype2
	epatch "${FILESDIR}"/freetype2-includes.patch
	# script aiding in manual installation required csh
	epatch "${FILESDIR}"/no-csh.patch
	# put files in sane places
	epatch "${FILESDIR}"/gentoo-paths-v2.patch
	# fix compilation with gcc-4
	epatch "${FILESDIR}"/gcc4-support.patch
	# fix bug #251681
	epatch "${FILESDIR}"/bug-251681.patch

	epatch "${FILESDIR}"/${P}-glibc-2.10.patch

	# respect CC etc
	sed -i \
		-e "s:CC  = /usr/bin/gcc:CC = $(tc-getCC):g" \
		-e "s:C++ = /usr/bin/g++:C++ = $(tc-getCXX):g" \
		-e "s:LD  = /usr/bin/g++:LD = $(tc-getCXX):g" \
		make/ivcommondefs || die
}

src_compile() {
	# -O2 segfaults on amd64 gcc-4.3 with ivman command (bicatali jun.08)
	replace-flags -O? -O1

	# VLDOPTS: find libraries during linking of executables
	# VLDDSOOPTS: find libraries during linking of libraries
	# VCFLAGS / VCXXFLAGS: pass user-chosen compiler flags
	# OPTIMIZER: do not override user-chosen compiler flags
	# system
	emake \
		VLDOPTS="-L${S}/lib -L${S}/libSoXt" \
		VLDDSOOPTS="-L${S}/lib -L${S}/libSoXt" \
		VCFLAGS="${CFLAGS}" VCXXFLAGS="${CXXFLAGS}" \
		OPTIMIZER= \
		|| die "Build failed"

	# fix RUNME-scripts in the demos directory for new paths
	sed -i \
		-e 's:/usr/share/:/usr/share/openinventor/:g' \
		-e 's:/usr/demos/:/usr/share/openinventor/demos/:g' \
		$(find apps/demos -name *.RUNME)
}

src_install() {
	# IVROOT: serves as DESTDIR
	# LLDOPTS: delete, so it won't go linking with libraries already on the
	# system
	# IVLIBDIR: multilib-strict compliance
	# LD_LIBRARY_PATH: support executables ran during install
	emake -j1 \
		IVROOT="${D}" \
		LLDOPTS= \
		IVLIBDIR="${D}usr/$(get_libdir)" \
		LD_LIBRARY_PATH="${D}usr/$(get_libdir)" \
		install \
		|| die "Install failed"

	# OpenInventor aliases for TrueType fonts
	local FONTDIR=/usr/share/fonts/corefonts
	local ALIASDIR=/usr/share/${PN}/fonts
	dodir ${ALIASDIR}
	dosym ${FONTDIR}/times.ttf ${ALIASDIR}/Times-Roman
	dosym ${FONTDIR}/arial.ttf ${ALIASDIR}/Helvetica
	dosym ${FONTDIR}/cour.ttf ${ALIASDIR}/Utopia-Regular
}
