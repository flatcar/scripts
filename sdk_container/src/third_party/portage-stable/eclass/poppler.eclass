# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/poppler.eclass,v 1.6 2010/01/03 19:10:49 scarabeus Exp $

# @ECLASS: poppler.eclass
# @MAINTAINER:
# Peter Alfredsen <loki_val@gentoo.org>
# @BLURB: Reduces code duplication in the modularized poppler ebuilds.
# @DESCRIPTION:
# Provides an easy template for making modularized poppler-based ebuilds.

inherit base multilib libtool

has 2 ${EAPI} || DEPEND="EAPI-TOO-OLD"

EXPORT_FUNCTIONS src_unpack src_prepare src_configure src_compile src_install

RDEPEND="
	!app-text/poppler
	!app-text/poppler-bindings
	"
DEPEND="
	dev-util/pkgconfig
	userland_GNU? ( >=sys-apps/findutils-4.4.0 )
	"


# @ECLASS-VARIABLE: HOMEPAGE
# @DESCRIPTION:
# Default HOMEPAGE
HOMEPAGE="http://poppler.freedesktop.org/"

# @ECLASS-VARIABLE: SRC_URI
# @DESCRIPTION:
# Default SRC_URI
SRC_URI="http://poppler.freedesktop.org/poppler-${PV}.tar.gz"

# @ECLASS-VARIABLE: S
# @DESCRIPTION:
# Default working directory
S=${WORKDIR}/poppler-${PV}

# @ECLASS-VARIABLE: POPPLER_MODULE
# @DESCRIPTION:
# The name of the poppler module. Must be set by the ebuild before inheriting
# the poppler eclass.
POPPLER_MODULE=${POPPLER_MODULE}

# @ECLASS-VARIABLE: POPPLER_MODULE_S
# @DESCRIPTION:
# The working directory of the poppler module.
POPPLER_MODULE_S=${S}/${POPPLER_MODULE}

# @FUNCTION: pkg_check_modules_override
# @USAGE: <GROUP> [package1] [package2]
# @DESCRIPTION:
# Will export the appropriate variables to override PKG_CHECK_MODULES autoconf
# macros, with the string " " by default. If packages are specified, they will
# be looked up with pkg-config and the appropriate LIBS and CFLAGS substituted.
# LIBS and CFLAGS can also be specified per-package with the following syntax:
# @CODE
# package=LIBS%CFLAGS
# @CODE
# = and % have no effect unless both are specified.
# Here is an example:
# @CODE
# 	pkg_check_modules_override GASH "gtk+-2.0=-jule%" gobject-2.0
# @CODE
# The above example will do:
# @CODE
# 	export GASH_CFLAGS+=" -jule"
# 	export GASH_LIBS+=" "
# 	export GASH_CFLAGS+=" $(pkg-config --cflags gobject-2.0)"
# 	export GASH_LIBS+=" $(pkg-config --libs gobject-2.0)"
# @CODE
#
# NOTE: If a package is not found, the string " " will be inserted in place of
# <GROUP>_CFLAGS  and <GROUP>_LIBS
pkg_check_modules_override() {
	local package
	local group="${1}"
	local packages="${*:2}"
	export ${group}_CFLAGS=" "
	export ${group}_LIBS=" "

	if [[ ${#@} -lt 1 ]]
	then
		eerror "${FUNCNAME[0]} requires at least one parameter: GROUP"
		eerror "PKG_CHECK_MODULES(GROUP, package1 package2 etc)"
		die "${FUNCNAME[0]} requires at least one parameter: GROUP"
	fi

	for package in $packages
	do
		if [[ ${package/=} != ${package} && ${package/\%} != ${package} ]]
		then
			package_cflag_libs=${package##*=}
			export ${group}_CFLAGS+=" ${package_cflag_libs%%\%*}"
			export ${group}_LIBS+=" ${package_cflag_libs##*\%}"
		else
			if pkg-config --exists $package
			then
				export ${group}_CFLAGS+=" $(pkg-config --cflags $package)"
				export ${group}_LIBS+=" $(pkg-config --libs $package)"
			else
			export ${group}_CFLAGS+=" "
			export ${group}_LIBS+=" "
			fi
		fi
	done
}
# @FUNCTION: poppler_src_unpack
# @USAGE:
# @DESCRIPTION:
# Runs unpack ${A}
poppler_src_unpack() {
	unpack ${A}
}

# @FUNCTION: poppler_src_prepare
# @USAGE:
# @DESCRIPTION:
# Runs autopatch from base.eclass.
# Uses sed to replace libpoppler.la references with -lpoppler
poppler_src_prepare() {
	base_src_prepare
	sed -i  \
		-e 's#$(top_builddir)/poppler/libpoppler.la#-lpoppler#' \
		$(find . -type f -name 'Makefile.in') || die "Failed to sed proper lib into Makefile.am"
	elibtoolize
}

# @FUNCTION: poppler_src_configure
# @USAGE:
# @DESCRIPTION:
# Makes sure we get a uniform Makefile environment by using pkg_check_modules_override to
# fill out some blanks that configure wants filled. Probably not really needed, but
# insures against future breakage.
# Calls econf with some defaults.
poppler_src_configure() {
	pkg_check_modules_override CAIRO cairo
	pkg_check_modules_override POPPLER_GLIB glib-2.0
	pkg_check_modules_override POPPLER_QT4 QtCore QtGui QtXml
	pkg_check_modules_override POPPLER_QT4_TEST QtTest
	pkg_check_modules_override ABIWORD libxml-2.0
	pkg_check_modules_override GTK_TEST gtk+-2.0 gdk-pixbuf-2.0 libglade-2.0 gthread-2.0
	pkg_check_modules_override POPPLER_GLIB glib-2.0 gobject-2.0

	econf 	--disable-static		\
		--enable-poppler-qt4		\
		--enable-poppler-glib		\
		--enable-xpdf-headers		\
		--enable-libjpeg		\
		--enable-libopenjpeg		\
		--enable-zlib			\
		--enable-splash-output		\
		${POPPLER_CONF}
}

# @FUNCTION: poppler_src_compile
# @USAGE:
# @DESCRIPTION:
# Removes top_srcdir Makefile to ensure that no accidental recursion happens. The build
# will just die if it tries to go through top_srcdir.
# Runs emake "$@" in POPPLER_MODULE_S
poppler_src_compile() {
	rm -f "${S}"/Makefile* &> /dev/null
	cd "${POPPLER_MODULE_S}" || die "POPPLER_MODULE_S=${POPPLER_MODULE_S} - cd failed"
	einfo "Now in $POPPLER_MODULE_S"
	emake "$@" || die "emake failed"
}

# @FUNCTION: poppler_src_install
# @USAGE:
# @DESCRIPTION:
# Runs emake DESTDIR="${D}" ${@:-install} in POPPLER_MODULE_S
# Removes .la files.
poppler_src_install() {
	cd "${POPPLER_MODULE_S}"
	emake DESTDIR="${D}" ${@:-install} || die "make install failed"
	for pfile in "${POPPLER_PKGCONFIG[@]}"
	do
		insinto /usr/$(get_libdir)/pkgconfig
		if [[ ${pfile/=} != ${pfile} ]]
		then
			if use ${pfile%=*}
			then
				pfile=${pfile#*=}
			else
				pfile=false
			fi
		fi
		[[ ${pfile} != "false" ]] && doins "${S}/${pfile}"
	done

	find "${D}" -type f -name '*.la' -exec rm -rf '{}' '+' || die "la removal failed"
}
