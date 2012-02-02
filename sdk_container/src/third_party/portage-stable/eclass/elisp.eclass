# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/elisp.eclass,v 1.44 2010/01/30 22:54:00 ulm Exp $
#
# Copyright 2002-2003 Matthew Kennedy <mkennedy@gentoo.org>
# Copyright 2003      Jeremy Maitin-Shepard <jbms@attbi.com>
# Copyright 2007-2009 Christian Faulhammer <fauli@gentoo.org>
# Copyright 2007-2010 Ulrich Müller <ulm@gentoo.org>
#
# @ECLASS: elisp.eclass
# @MAINTAINER:
# Feel free to contact the Emacs team through <emacs@gentoo.org> if you
# have problems, suggestions or questions.
# @BLURB: Eclass for Emacs Lisp packages
# @DESCRIPTION:
#
# This eclass is designed to install elisp files of Emacs related
# packages into the site-lisp directory. The majority of elisp packages
# will only need to define the standard ebuild variables (like SRC_URI)
# and optionally SITEFILE for successful installation.
#
# Emacs support for other than pure elisp packages is handled by
# elisp-common.eclass where you won't have a dependency on Emacs itself.
# All elisp-* functions are documented there.
#
# If the package's source is a single (in whatever way) compressed elisp
# file with the file name ${P}.el, then this eclass will move ${P}.el to
# ${PN}.el in src_unpack().

# @ECLASS-VARIABLE: NEED_EMACS
# @DESCRIPTION:
# If you need anything different from Emacs 21, use the NEED_EMACS
# variable before inheriting elisp.eclass.  Set it to the major version
# your package uses and the dependency will be adjusted.

# @ECLASS-VARIABLE: ELISP_PATCHES
# @DESCRIPTION:
# Any patches to apply after unpacking the sources. Patches are searched
# both in ${PWD} and ${FILESDIR}.

# @ECLASS-VARIABLE: SITEFILE
# @DESCRIPTION:
# Name of package's site-init file.  The filename must match the shell
# pattern "[1-8][0-9]*-gentoo.el"; numbers below 10 and above 89 are
# reserved for internal use.  "50${PN}-gentoo.el" is a reasonable choice
# in most cases.

# @ECLASS-VARIABLE: ELISP_TEXINFO
# @DESCRIPTION:
# Space separated list of Texinfo sources. Respective GNU Info files
# will be generated in src_compile() and installed in src_install().

# @ECLASS-VARIABLE: DOCS
# @DESCRIPTION:
# DOCS="blah.txt ChangeLog" is automatically used to install the given
# files by dodoc in src_install().

inherit elisp-common eutils

case "${EAPI:-0}" in
	0|1) EXPORT_FUNCTIONS src_{unpack,compile,install} \
		pkg_{setup,postinst,postrm} ;;
	*) EXPORT_FUNCTIONS src_{unpack,prepare,configure,compile,install} \
		pkg_{setup,postinst,postrm} ;;
esac

DEPEND=">=virtual/emacs-${NEED_EMACS:-21}"
RDEPEND="${DEPEND}"
IUSE=""

elisp_pkg_setup() {
	local need_emacs=${NEED_EMACS:-21}
	local have_emacs=$(elisp-emacs-version)
	if [ "${have_emacs%%.*}" -lt "${need_emacs%%.*}" ]; then
		eerror "This package needs at least Emacs ${need_emacs%%.*}."
		eerror "Use \"eselect emacs\" to select the active version."
		die "Emacs version ${have_emacs} is too low."
	fi
	einfo "Emacs version: ${have_emacs}"
}

elisp_src_unpack() {
	[ -n "${A}" ] && unpack ${A}
	if [ -f ${P}.el ]; then
		# the "simple elisp" case with a single *.el file in WORKDIR
		mv ${P}.el ${PN}.el || die
		[ -d "${S}" ] || S=${WORKDIR}
	fi

	case "${EAPI:-0}" in
		0|1) [ -d "${S}" ] && cd "${S}"
			elisp_src_prepare ;;
	esac
}

elisp_src_prepare() {
	local patch
	for patch in ${ELISP_PATCHES}; do
		if [ -f "${patch}" ]; then
			epatch "${patch}"
		elif [ -f "${WORKDIR}/${patch}" ]; then
			epatch "${WORKDIR}/${patch}"
		elif [ -f "${FILESDIR}/${patch}" ]; then
			epatch "${FILESDIR}/${patch}"
		else
			die "Cannot find ${patch}"
		fi
	done
}

elisp_src_configure() { :; }

elisp_src_compile() {
	elisp-compile *.el || die
	if [ -n "${ELISP_TEXINFO}" ]; then
		makeinfo ${ELISP_TEXINFO} || die
	fi
}

elisp_src_install() {
	elisp-install ${PN} *.el *.elc || die
	if [ -n "${SITEFILE}" ]; then
		elisp-site-file-install "${FILESDIR}/${SITEFILE}" || die
	fi
	if [ -n "${ELISP_TEXINFO}" ]; then
		set -- ${ELISP_TEXINFO}
		doinfo ${@/%.*/.info*} || die
	fi
	if [ -n "${DOCS}" ]; then
		dodoc ${DOCS} || die
	fi
}

elisp_pkg_postinst() {
	elisp-site-regen
}

elisp_pkg_postrm() {
	elisp-site-regen
}
