# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/xfconf.eclass,v 1.7 2010/01/23 17:36:34 angelos Exp $

# @ECLASS: xfconf.eclass
# @MAINTAINER:
# XFCE maintainers <xfce@gentoo.org>
# @BLURB: Default XFCE ebuild layout
# @DESCRIPTION:
# Default XFCE ebuild layout

# @ECLASS-VARIABLE: EAUTORECONF
# @DESCRIPTION:
# Run eautoreconf instead of elibtoolize if set "yes"

# @ECLASS-VARIABLE: EINTLTOOLIZE
# @DESCRIPTION:
# Run intltoolize --force --copy --automake if set "yes"

# @ECLASS-VARIABLE: DOCS
# @DESCRIPTION:
# Define documentation to install

# @ECLASS-VARIABLE: PATCHES
# @DESCRIPTION:
# Define patches to apply

# @ECLASS-VARIABLE: XFCONF
# @DESCRIPTION:
# Define options for econf

inherit autotools base fdo-mime gnome2-utils libtool

if ! [[ ${MY_P} ]]; then
	MY_P=${P}
else
	S=${WORKDIR}/${MY_P}
fi

SRC_URI="mirror://xfce/xfce/${PV}/src/${MY_P}.tar.bz2"

if [[ "${EINTLTOOLIZE}" == "yes" ]]; then
	_xfce4_intltool="dev-util/intltool"
fi

if [[ "${EAUTORECONF}" == "yes" ]]; then
	_xfce4_m4="dev-util/xfce4-dev-tools"
fi

RDEPEND=""
DEPEND="${_xfce4_intltool}
	${_xfce4_m4}"

unset _xfce4_intltool
unset _xfce4_m4

XFCONF_EXPF="src_unpack src_compile src_install pkg_preinst pkg_postinst pkg_postrm"
case ${EAPI:-0} in
	3|2) XFCONF_EXPF="${XFCONF_EXPF} src_prepare src_configure" ;;
	1|0) ;;
	*) die "Unknown EAPI." ;;
esac
EXPORT_FUNCTIONS ${XFCONF_EXPF}

# @FUNCTION: xfconf_src_unpack
# @DESCRIPTION:
# Run base_src_util autopatch and eautoreconf or elibtoolize
xfconf_src_unpack() {
	unpack ${A}
	cd "${S}"
	has src_prepare ${XFCONF_EXPF} || xfconf_src_prepare
}

# @FUNCTION: xfconf_src_prepare
# @DESCRIPTION:
# Run base_src_util autopatch and eautoreconf or elibtoolize
xfconf_src_prepare() {
	base_src_prepare

	if [[ "${EINTLTOOLIZE}" == "yes" ]]; then
		intltoolize --force --copy --automake || die "intltoolize failed"
	fi

	if [[ "${EAUTORECONF}" == "yes" ]]; then
		AT_M4DIR="/usr/share/xfce4/dev-tools/m4macros" eautoreconf
	else
		elibtoolize
	fi
}

# @FUNCTION: xfconf_src_configure
# @DESCRIPTION:
# Run econf with opts in XFCONF variable
xfconf_src_configure() {
	econf ${XFCONF}
}

# @FUNCTION: xfconf_src_compile
# @DESCRIPTION:
# Run econf with opts in XFCONF variable
xfconf_src_compile() {
	has src_configure ${XFCONF_EXPF} || xfconf_src_configure
	emake || die "emake failed"
}

# @FUNCTION: xfconf_src_install
# @DESCRIPTION:
# Run emake install and install documentation in DOCS variable
xfconf_src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	if [[ -n ${DOCS} ]]; then
		dodoc ${DOCS} || die "dodoc failed"
	fi
}

# @FUNCTION: xfconf_pkg_preinst
# @DESCRIPTION:
# Run gnome2_icon_savelist
xfconf_pkg_preinst() {
	gnome2_icon_savelist
}

# @FUNCTION: xfconf_pkg_postinst
# @DESCRIPTION:
# Run fdo-mime_{desktop,mime}_database_update and gnome2_icon_cache_update
xfconf_pkg_postinst() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update
}

# @FUNCTION: xfconf_pkg_postrm
# @DESCRIPTION:
# Run fdo-mime_{desktop,mime}_database_update and gnome2_icon_cache_update
xfconf_pkg_postrm() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update
}
