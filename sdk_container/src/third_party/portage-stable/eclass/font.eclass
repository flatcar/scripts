# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/font.eclass,v 1.48 2010/02/09 17:15:08 scarabeus Exp $

# @ECLASS: font.eclass
# @MAINTAINER:
# fonts@gentoo.org

# Author: Tomáš Chvátal <scarabeus@gentoo.org>
# Author: foser <foser@gentoo.org>
# @BLURB: Eclass to make font installation uniform

inherit eutils

EXPORT_FUNCTIONS pkg_setup src_install pkg_postinst pkg_postrm

# @ECLASS-VARIABLE: FONT_SUFFIX
# @DESCRIPTION:
# Space delimited list of font suffixes to install
FONT_SUFFIX=${FONT_SUFFIX:=}

# @ECLASS-VARIABLE: FONT_S
# @DESCRIPTION:
# Dir containing the fonts
FONT_S=${FONT_S:=${S}}

# @ECLASS-VARIABLE: FONT_PN
# @DESCRIPTION:
# Last part of $FONTDIR
FONT_PN=${FONT_PN:=${PN}}

# @ECLASS-VARIABLE: FONTDIR
# @DESCRIPTION:
# This is where the fonts are installed
FONTDIR=${FONTDIR:-/usr/share/fonts/${FONT_PN}}

# @ECLASS-VARIABLE: FONT_CONF
# @DESCRIPTION:
# Array, which element(s) is(are) path(s) of fontconfig-2.4 file(s) to install
FONT_CONF=( "" )

# @ECLASS-VARIABLE: DOCS
# @DESCRIPTION:
# Docs to install
DOCS=${DOCS:-}

IUSE="X"

DEPEND="X? (
		x11-apps/mkfontdir
		media-fonts/encodings
	)
	>=media-libs/fontconfig-2.4.0"

# @FUNCTION: font_xfont_config
# @DESCRIPTION:
# Creates the Xfont files.
font_xfont_config() {
	# create Xfont files
	if has X ${IUSE//+} && use X ; then
		ebegin "Creating fonts.scale & fonts.dir"
		rm -f "${ED}${FONTDIR}"/fonts.{dir,scale}
		mkfontscale "${ED}${FONTDIR}"
		mkfontdir \
			-e ${EPREFIX}/usr/share/fonts/encodings \
			-e ${EPREFIX}/usr/share/fonts/encodings/large \
			"${ED}${FONTDIR}"
		eend $?
		if [ -e "${FONT_S}/fonts.alias" ] ; then
			doins "${FONT_S}/fonts.alias"
		fi
	fi
}

# @FUNCTION: font_fontconfig
# @DESCRIPTION:
# Installs the fontconfig config files of FONT_CONF.
font_fontconfig() {
	local conffile
	if [[ -n ${FONT_CONF[@]} ]]; then
		insinto /etc/fonts/conf.avail/
		for conffile in "${FONT_CONF[@]}"; do
			[[ -e  ${conffile} ]] && doins ${conffile}
		done
	fi
}

# @FUNCTION: font_src_install
# @DESCRIPTION:
# The font src_install function.
font_src_install() {
	local suffix commondoc

	pushd "${FONT_S}" > /dev/null

	insinto "${FONTDIR}"

	for suffix in ${FONT_SUFFIX}; do
		doins *.${suffix}
	done

	rm -f fonts.{dir,scale} encodings.dir

	font_xfont_config
	font_fontconfig

	popd > /dev/null

	[[ -n ${DOCS} ]] && { dodoc ${DOCS} || die "docs installation failed" ; }

	# install common docs
	for commondoc in COPYRIGHT README{,.txt} NEWS AUTHORS BUGS ChangeLog FONTLOG.txt; do
		[[ -s ${commondoc} ]] && dodoc ${commondoc}
	done
}

# @FUNCTION: font_pkg_setup
# @DESCRIPTION:
# The font pkg_setup function.
# Collision portection and Prefix compat for eapi < 3.
font_pkg_setup() {
	# Prefix compat
	case ${EAPI:-0} in
		0|1|2)
			if ! use prefix; then
				EPREFIX=
				ED=${D}
				EROOT=${ROOT}
				[[ ${EROOT} = */ ]] || EROOT+="/"
			fi
			;;
	esac

	# make sure we get no collisions
	# setup is not the nicest place, but preinst doesn't cut it
	[[ -e "${EROOT}/${FONTDIR}/fonts.cache-1" ]] && rm -f "${EROOT}/${FONTDIR}/fonts.cache-1"
}

# @FUNCTION: font_pkg_postinst
# @DESCRIPTION:
# The font pkg_postinst function.
# Update global font cache and fix permissions.
font_pkg_postinst() {
	# unreadable font files = fontconfig segfaults
	find "${EROOT}"usr/share/fonts/ -type f '!' -perm 0644 -print0 \
		| xargs -0 chmod -v 0644 2>/dev/null

	if [[ -n ${FONT_CONF[@]} ]]; then
		local conffile
		echo
		elog "The following fontconfig configuration files have been installed:"
		elog
		for conffile in "${FONT_CONF[@]}"; do
			if [[ -e ${EROOT}etc/fonts/conf.avail/$(basename ${conffile}) ]]; then
				elog "  $(basename ${conffile})"
			fi
		done
		elog
		elog "Use \`eselect fontconfig\` to enable/disable them."
		echo
	fi

	if [[ ${ROOT} == / ]]; then
		ebegin "Updating global fontcache"
		fc-cache -fs
		eend $?
	fi
}

# @FUNCTION: font_pkg_postrm
# @DESCRIPTION:
# The font pkg_postrm function.
# Updates global font cache
font_pkg_postrm() {
	# unreadable font files = fontconfig segfaults
	find "${EROOT}"usr/share/fonts/ -type f '!' -perm 0644 -print0 \
		| xargs -0 chmod -v 0644 2>/dev/null

	if [[ ${ROOT} == / ]]; then
		ebegin "Updating global fontcache"
		fc-cache -fs
		eend $?
	fi
}
