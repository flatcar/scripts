# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/gnustep-base.eclass,v 1.14 2009/12/05 16:10:30 grobian Exp $

inherit eutils flag-o-matic

# Inner gnustep eclass, should only be inherited directly by gnustep-base
# packages
#
# maintainer: GNUstep Herd <gnustep@gentoo.org>

# IUSE variables across all GNUstep packages
# "debug": enable code for debugging
# "doc": build and install documentation, if available
IUSE="debug doc"

# packages needed to build any base gnustep package
GNUSTEP_CORE_DEPEND="doc? ( virtual/texi2dvi dev-tex/latex2html app-text/texi2html )"

# Where to install GNUstep
GNUSTEP_PREFIX="${EPREFIX}/usr/GNUstep"

# GNUstep environment array
typeset -a GS_ENV

# Ebuild function overrides
gnustep-base_pkg_setup() {
	if test_version_info 3.3 ; then
		strip-unsupported-flags
	elif test_version_info 3.4 ; then
		# strict-aliasing is known to break obj-c stuff in gcc-3.4*
		filter-flags -fstrict-aliasing
	fi

	# known to break ObjC (bug 86089)
	filter-flags -fomit-frame-pointer
}

gnustep-base_src_unpack() {
	unpack ${A}
	cd "${S}"

	gnustep-base_src_prepare
}

gnustep-base_src_prepare() {
	if [[ -f ./GNUmakefile ]] ; then
		# Kill stupid includes that are simply overdone or useless on normal
		# Gentoo, but (may) cause major headaches on Prefixed Gentoo.  If this
		# only removes a part of a path it's good that it bails out, as we want
		# to know when they use some direct include.
		ebegin "Cleaning paths from GNUmakefile"
		sed -i \
			-e 's|-I/usr/X11R6/include||g' \
			-e 's|-I/usr/include||g' \
			-e 's|-L/usr/X11R6/lib||g' \
			-e 's|-L/usr/lib||g' \
			GNUmakefile
		eend $?
	fi
}

gnustep-base_src_configure() {
	egnustep_env
	if [[ -x ./configure ]] ; then
		econf || die "configure failed"
	fi
}

gnustep-base_src_compile() {
	egnustep_env
	case ${EAPI:-0} in
		0|1) gnustep-base_src_configure ;;
	esac

	egnustep_make
}

gnustep-base_src_install() {
	egnustep_env
	egnustep_install
	if use doc ; then
		egnustep_env
		egnustep_doc
	fi
	egnustep_install_config
}

gnustep-base_pkg_postinst() {
	[[ $(type -t gnustep_config_script) != "function" ]] && return 0

	elog "To use this package, as *user* you should run:"
	elog "  ${GNUSTEP_SYSTEM_TOOLS}/Gentoo/config-${PN}.sh"
}

# Clean/reset an ebuild to the installed GNUstep environment
egnustep_env() {
	# Get additional variables
	GNUSTEP_SH_EXPORT_ALL_VARIABLES="true"

	if [[ -f ${GNUSTEP_PREFIX}/System/Library/Makefiles/GNUstep.sh ]] ; then
		# Reset GNUstep variables
		source "${GNUSTEP_PREFIX}"/System/Library/Makefiles/GNUstep-reset.sh
		source "${GNUSTEP_PREFIX}"/System/Library/Makefiles/GNUstep.sh

		# Needed to run installed GNUstep apps in sandbox
		addpredict "/root/GNUstep"

		# Set rpath in ldflags when available
		case ${CHOST} in
			*-linux-gnu|*-solaris*)
				is-ldflagq -Wl,-rpath="${GNUSTEP_SYSTEM_LIBRARIES}" \
					|| append-ldflags \
						-Wl,-rpath="${GNUSTEP_SYSTEM_LIBRARIES}"
			;;
		esac

		# Set up env vars for make operations
		GS_ENV=( AUXILIARY_LDFLAGS="${LDFLAGS}" \
			ADDITIONAL_NATIVE_LIB_DIRS="${GNUSTEP_SYSTEM_LIBRARIES}" \
			DESTDIR="${D}" \
			HOME="${T}" \
			GNUSTEP_USER_DIR="${T}" \
			GNUSTEP_USER_DEFAULTS_DIR="${T}"/Defaults \
			GNUSTEP_INSTALLATION_DOMAIN=SYSTEM \
			TAR_OPTIONS="${TAR_OPTIONS} --no-same-owner" \
			messages=yes )

		# Parallel-make support was added in gnustep-make 2.2.0
		has_version "<gnustep-base/gnustep-make-2.2.0" \
			&& GS_ENV=( "${GS_ENV[@]}" "-j1" )

		use debug \
			&& GS_ENV=( "${GS_ENV[@]}" "debug=yes" ) \
			|| GS_ENV=( "${GS_ENV[@]}" "debug=no" )

		return 0
	fi
	die "gnustep-make not installed!"
}

# Make utilizing GNUstep Makefiles
egnustep_make() {
	if [[ -f ./Makefile || -f ./makefile || -f ./GNUmakefile ]] ; then
		emake ${*} "${GS_ENV[@]}" all || die "package make failed"
		return 0
	fi
	die "no Makefile found"
}

# Make-install utilizing GNUstep Makefiles
egnustep_install() {
	# avoid problems due to our "weird" prefix, make sure it exists
	mkdir -p "${D}"${GNUSTEP_SYSTEM_TOOLS}
	if [[ -f ./[mM]akefile || -f ./GNUmakefile ]] ; then
		emake ${*} "${GS_ENV[@]}" install || die "package install failed"
		return 0
	fi
	die "no Makefile found"
}

# Make and install docs using GNUstep Makefiles
egnustep_doc() {
	if [[ -d ./Documentation ]] ; then
		# Check documentation presence
		cd "${S}"/Documentation
		if [[ -f ./[mM]akefile || -f ./GNUmakefile ]] ; then
			emake "${GS_ENV[@]}" all || die "doc make failed"
			emake "${GS_ENV[@]}" install || die "doc install failed"
		fi
		cd ..
	fi
}

egnustep_install_config() {
	[[ $(type -t gnustep_config_script) != "function" ]] && return 0

	local cfile=config-${PN}.sh

	cat << 'EOF' > "${T}"/${cfile}
#!/usr/bin/env bash
gnustep_append_default() {
	if [[ -z $1 || -z $2 || -z $3 ]]; then
		echo "warning: invalid script invocation"
		return
	fi
	dom=$1
	key=$2
	val=$3
	cur=$(defaults read ${dom} ${key}) 2> /dev/null
	if [[ -z $cur ]] ; then
		echo " * setting ${dom} ${key}"
		defaults write ${dom} ${key} "( ${val} )"
	elif [[ ${cur} != *${val}* ]] ; then
		echo " * adding ${val} to ${dom} ${key}"
		echo "${cur%)\'}, \"${val}\" )'" | defaults write
	else
		echo " * ${val} already present in ${dom} ${key}"
	fi
}

gnustep_set_default() {
	if [[ -z $1 || -z $2 || -z $3 ]]; then
		echo "warning: invalid script invocation"
		return
	fi
	dom=$1
	key=$2
	val=$3
	echo " * setting ${dom} ${key}"
	defaults write ${dom} ${key} ${val}
}

EOF

	echo "echo \"Applying ${P} default configuration ...\"" >> "${T}"/${cfile}

	gnustep_config_script | \
	while read line ; do
		echo "${line}" >> "${T}"/${cfile}
	done
	echo 'echo "done"' >> "${T}"/${cfile}

	exeinto ${GNUSTEP_SYSTEM_TOOLS#${EPREFIX}}/Gentoo
	doexe "${T}"/${cfile}
}

case ${EAPI:-0} in
	0|1) EXPORT_FUNCTIONS pkg_setup src_unpack src_compile src_install pkg_postinst ;;
	2) EXPORT_FUNCTIONS pkg_setup src_prepare src_configure src_compile src_install pkg_postinst ;;
esac
