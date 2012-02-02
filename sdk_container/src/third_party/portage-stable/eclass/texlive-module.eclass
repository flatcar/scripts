# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/texlive-module.eclass,v 1.34 2010/01/13 15:16:49 fauli Exp $

# @ECLASS: texlive-module.eclass
# @MAINTAINER:
# tex@gentoo.org
#
# Original Author: Alexis Ballier <aballier@gentoo.org>
# @BLURB: Provide generic install functions so that modular texlive's texmf ebuild will only have to inherit this eclass
# @DESCRIPTION:
# Purpose: Provide generic install functions so that modular texlive's texmf ebuilds will
# only have to inherit this eclass.
# Ebuilds have to provide TEXLIVE_MODULE_CONTENTS variable that contains the list
# of packages that it will install. (See below)
#
# What is assumed is that it unpacks texmf and texmf-dist directories to
# ${WORKDIR}.
#
# It inherits texlive-common

# @ECLASS-VARIABLE: TEXLIVE_MODULE_CONTENTS
# @DESCRIPTION:
# The list of packages that will be installed. This variable will be expanded to
# SRC_URI:
#
# For TeX Live 2008: foo -> texlive-module-foo-${PV}.tar.lzma
# For TeX Live 2009: foo -> texlive-module-foo-${PV}.tar.xz

# @ECLASS-VARIABLE: TEXLIVE_MODULE_DOC_CONTENTS
# @DESCRIPTION:
# The list of packages that will be installed if the doc useflag is enabled.
# Expansion to SRC_URI is the same as for TEXLIVE_MODULE_CONTENTS. This is only
# valid for TeX Live 2008 and later

# @ECLASS-VARIABLE: TEXLIVE_MODULE_SRC_CONTENTS
# @DESCRIPTION:
# The list of packages that will be installed if the source useflag is enabled.
# Expansion to SRC_URI is the same as for TEXLIVE_MODULE_CONTENTS. This is only
# valid for TeX Live 2008 and later

# @ECLASS-VARIABLE: TEXLIVE_MODULE_BINSCRIPTS
# @DESCRIPTION:
# A space separated list of files that are in fact scripts installed in the
# texmf tree and that we want to be available directly. They will be installed in
# /usr/bin.

# @ECLASS-VARIABLE: TL_PV
# @DESCRIPTION:
# Normally the module's PV reflects the TeXLive release it belongs to.
# If this is not the case, TL_PV takes the version number for the
# needed app-text/texlive-core.

inherit texlive-common

HOMEPAGE="http://www.tug.org/texlive/"

COMMON_DEPEND=">=app-text/texlive-core-${TL_PV:-${PV}}"

IUSE="source"

# TeX Live 2008 was providing .tar.lzma files of CTAN packages. For 2009 they are now
# .tar.xz
if [ "${PV#2008}" != "${PV}" ]; then
	PKGEXT=tar.lzma
	DEPEND="${COMMON_DEPEND}
		|| ( app-arch/xz-utils app-arch/lzma-utils )"
else
	PKGEXT=tar.xz
	DEPEND="${COMMON_DEPEND}
		app-arch/xz-utils"
fi

for i in ${TEXLIVE_MODULE_CONTENTS}; do
	SRC_URI="${SRC_URI} mirror://gentoo/texlive-module-${i}-${PV}.${PKGEXT}"
done

# Forge doc SRC_URI
[ -n "${PN##*documentation*}" ] && [ -n "${TEXLIVE_MODULE_DOC_CONTENTS}" ] && SRC_URI="${SRC_URI} doc? ("
for i in ${TEXLIVE_MODULE_DOC_CONTENTS}; do
	SRC_URI="${SRC_URI} mirror://gentoo/texlive-module-${i}-${PV}.${PKGEXT}"
done
[ -n "${PN##*documentation*}" ] && [ -n "${TEXLIVE_MODULE_DOC_CONTENTS}" ] && SRC_URI="${SRC_URI} )"

# Forge source SRC_URI
if [ -n "${TEXLIVE_MODULE_SRC_CONTENTS}" ] ; then
	SRC_URI="${SRC_URI} source? ("
	for i in ${TEXLIVE_MODULE_SRC_CONTENTS}; do
		SRC_URI="${SRC_URI} mirror://gentoo/texlive-module-${i}-${PV}.${PKGEXT}"
	done
	SRC_URI="${SRC_URI} )"
fi

RDEPEND="${COMMON_DEPEND}"

[ -z "${PN##*documentation*}" ] || IUSE="${IUSE} doc"

S="${WORKDIR}"

if [ "${PV#2008}" == "${PV}" ]; then

# @FUNCTION: texlive-module_src_unpack
# @DESCRIPTION:
# Only for TeX Live 2009.
# Gives tar.xz unpack support until we can use an EAPI with that support.

RELOC_TARGET=texmf-dist

texlive-module_src_unpack() {
	local i s
	for i in ${A}
	do
		s="${DISTDIR%/}/${i}"
		einfo "Unpacking ${s} to ${PWD}"
		test -s "${s}" || die "${s} does not exist"
		xz -dc -- "${s}" | tar xof - || die "Unpacking ${s} failed"
	done
	grep RELOC tlpkg/tlpobj/* | awk '{print $2}' | sed 's#^RELOC/##' > "${T}/reloclist"
	{ for i in $(<"${T}/reloclist"); do  dirname $i; done; } | uniq > "${T}/dirlist"
	for i in $(<"${T}/dirlist"); do
		[ -d "${RELOC_TARGET}/${i}" ] || mkdir -p "${RELOC_TARGET}/${i}"
	done
	for i in $(<"${T}/reloclist"); do
		mv "${i}" "${RELOC_TARGET}"/$(dirname "${i}") || die "failed to relocate ${i} to ${RELOC_TARGET}/$(dirname ${i})"
	done
}

fi

# @FUNCTION: texlive-module_add_format
# @DESCRIPTION:
# Creates/appends to a format.${PN}.cnf file for fmtutil.
# This will make fmtutil generate the formats when asked and allow the remaining
# src_compile phase to build the formats

texlive-module_add_format() {
	local name engine mode patterns options
	eval $@
	einfo "Appending to format.${PN}.cnf for $@"
	[ -d texmf/fmtutil ] || mkdir -p texmf/fmtutil
	[ -f texmf/fmtutil/format.${PN}.cnf ] || { echo "# Generated for ${PN} by texlive-module.eclass" > texmf/fmtutil/format.${PN}.cnf; }
	if [ "${mode}" == "disabled" ]; then
		printf "#! " >> texmf/fmtutil/format.${PN}.cnf
	fi
	[ -z "${patterns}" ] && patterns="-"
	printf "${name}\t${engine}\t${patterns}\t${options}\n" >> texmf/fmtutil/format.${PN}.cnf
}

# @FUNCTION: texlive-module_make_language_def_lines
# @DESCRIPTION:
# Creates a language.${PN}.def entry to put in /etc/texmf/language.def.d
# It parses the AddHyphen directive of tlpobj files to create it.

texlive-module_make_language_def_lines() {
	local lefthyphenmin righthyphenmin synonyms name file
	eval $@
	einfo "Generating language.def entry for $@"
	[ -z "$lefthyphenmin" ] && lefthyphenmin="2"
	[ -z "$righthyphenmin" ] && righthyphenmin="3"
	echo "\\addlanguage{$name}{$file}{}{$lefthyphenmin}{$righthyphenmin}" >> "${S}/language.${PN}.def"
	if [ -n "$synonyms" ] ; then
		for i in $(echo $synonyms | tr ',' ' ') ; do
			einfo "Generating language.def synonym $i for $@"
			echo "\\addlanguage{$i}{$file}{}{$lefthyphenmin}{$righthyphenmin}" >> "${S}/language.${PN}.def"
		done
	fi
}

# @FUNCTION: texlive-module_make_language_dat_lines
# @DESCRIPTION:
# Only valid for TeXLive 2008.
# Creates a language.${PN}.dat entry to put in /etc/texmf/language.dat.d
# It parses the AddHyphen directive of tlpobj files to create it.

texlive-module_make_language_dat_lines() {
	local lefthyphenmin righthyphenmin synonyms name file
	eval $@
	einfo "Generating language.dat entry for $@"
	echo "$name $file" >> "${S}/language.${PN}.dat"
	if [ -n "$synonyms" ] ; then
		for i in $(echo $synonyms | tr ',' ' ') ; do
			einfo "Generating language.dat synonym $i for $@"
			echo "=$i" >> "${S}/language.${PN}.dat"
		done
	fi
}

# @FUNCTION: texlive-module_src_compile
# @DESCRIPTION:
# exported function:
# Will look for format.foo.cnf and build foo format files using fmtutil
# (provided by texlive-core). The compiled format files will be sent to
# texmf-var/web2c, like fmtutil defaults to but with some trick to stay in the
# sandbox
# The next step is to generate config files that are to be installed in
# /etc/texmf; texmf-update script will take care of merging the different config
# files for different packages in a single one used by the whole tex installation.

texlive-module_src_compile() {
	# Generate config files
	# TeX Live 2007 was providing lists. For 2008 they are now tlpobj.
	for i in "${S}"/tlpkg/tlpobj/*;
	do
		grep '^execute ' "${i}" | sed -e 's/^execute //' | tr ' ' '@' |sort|uniq >> "${T}/jobs"
	done

	for i in $(<"${T}/jobs");
	do
		j="$(echo $i | tr '@' ' ')"
		command=${j%% *}
		parameter=${j#* }
		case "${command}" in
			addMap)
				echo "Map ${parameter}" >> "${S}/${PN}.cfg";;
			addMixedMap)
				echo "MixedMap ${parameter}" >> "${S}/${PN}.cfg";;
			addDvipsMap)
				echo "p	+${parameter}" >> "${S}/${PN}-config.ps";;
			addDvipdfmMap)
				echo "f	${parameter}" >> "${S}/${PN}-config";;
			AddHyphen)
				texlive-module_make_language_def_lines "$parameter"
				texlive-module_make_language_dat_lines "$parameter";;
			AddFormat)
				texlive-module_add_format "$parameter";;
			BuildFormat)
				einfo "Format $parameter already built.";;
			BuildLanguageDat)
				einfo "Language file $parameter already generated.";;
			*)
				die "No rule to proccess ${command}. Please file a bug."
		esac
	done

	# Build format files
	for i in texmf/fmtutil/format*.cnf; do
		if [ -f "${i}" ]; then
			einfo "Building format ${i}"
			VARTEXFONTS="${T}/fonts" TEXMFHOME="${S}/texmf:${S}/texmf-dist:${S}/texmf-var"\
				env -u TEXINPUTS fmtutil --cnffile "${i}" --fmtdir "${S}/texmf-var/web2c" --all\
				|| die "failed to build format ${i}"
		fi
	done

	# Delete ls-R files, these should not be created but better be certain they
	# do not end up being installed.
	find . -name 'ls-R' -delete
}

# @FUNCTION: texlive-module_src_install
# @DESCRIPTION:
# exported function:
# Install texmf and config files to the system

texlive-module_src_install() {
	for i in texmf/fmtutil/format*.cnf; do
		[ -f "${i}" ] && etexlinks "${i}"
	done

	dodir /usr/share
	if [ -z "${PN##*documentation*}" ] || use doc; then
		[ -d texmf-doc ] && cp -pR texmf-doc "${D}/usr/share/"
	else
		[ -d texmf/doc ] && rm -rf texmf/doc
		[ -d texmf-dist/doc ] && rm -rf texmf-dist/doc
	fi

	[ -d texmf ] && cp -pR texmf "${D}/usr/share/"
	[ -d texmf-dist ] && cp -pR texmf-dist "${D}/usr/share/"
	[ -d tlpkg ] && use source && cp -pR tlpkg "${D}/usr/share/"

	insinto /var/lib/texmf
	[ -d texmf-var ] && doins -r texmf-var/*

	insinto /etc/texmf/updmap.d
	[ -f "${S}/${PN}.cfg" ] && doins "${S}/${PN}.cfg"
	insinto /etc/texmf/dvips.d
	[ -f "${S}/${PN}-config.ps" ] && doins "${S}/${PN}-config.ps"
	insinto /etc/texmf/dvipdfm/config
	[ -f "${S}/${PN}-config" ] && doins "${S}/${PN}-config"

	if [ -f "${S}/language.${PN}.def" ] ; then
		insinto /etc/texmf/language.def.d
		doins "${S}/language.${PN}.def"
	fi

	if [ -f "${S}/language.${PN}.dat" ] ; then
		insinto /etc/texmf/language.dat.d
		doins "${S}/language.${PN}.dat"
	fi
	[ -n "${TEXLIVE_MODULE_BINSCRIPTS}" ] && dobin_texmf_scripts ${TEXLIVE_MODULE_BINSCRIPTS}

	texlive-common_handle_config_files
}

# @FUNCTION: texlive-module_pkg_postinst
# @DESCRIPTION:
# exported function:
# run texmf-update to ensure the tex installation is consistent with the
# installed texmf trees.

texlive-module_pkg_postinst() {
	if [ "$ROOT" = "/" ] && [ -x /usr/sbin/texmf-update ] ; then
		/usr/sbin/texmf-update
	else
		ewarn "Cannot run texmf-update for some reason."
		ewarn "Your texmf tree might be inconsistent with your configuration"
		ewarn "Please try to figure what has happened"
	fi
}

# @FUNCTION: texlive-module_pkg_postrm
# @DESCRIPTION:
# exported function:
# run texmf-update to ensure the tex installation is consistent with the
# installed texmf trees.

texlive-module_pkg_postrm() {
	if [ "$ROOT" = "/" ] && [ -x /usr/sbin/texmf-update ] ; then
		/usr/sbin/texmf-update
	else
		ewarn "Cannot run texmf-update for some reason."
		ewarn "Your texmf tree might be inconsistent with your configuration"
		ewarn "Please try to figure what has happened"
	fi
}

if [ "${PV#2008}" != "${PV}" ]; then
EXPORT_FUNCTIONS src_compile src_install pkg_postinst pkg_postrm
else
EXPORT_FUNCTIONS src_unpack src_compile src_install pkg_postinst pkg_postrm
fi
