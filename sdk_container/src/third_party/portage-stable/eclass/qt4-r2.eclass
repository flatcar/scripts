# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/qt4-r2.eclass,v 1.12 2011/08/22 04:46:32 vapier Exp $

# @ECLASS: qt4-r2.eclass
# @MAINTAINER:
# Ben de Groot <yngwin@gentoo.org>,
# Markos Chandras <hwoarang@gentoo.org>,
# Davide Pesavento <davidepesa@gmail.com>,
# Dominik Kapusta <ayoy@gentoo.org>
# @BLURB: Eclass for Qt4 packages, second edition
# @DESCRIPTION:
# This eclass contains various functions that may be useful when
# dealing with packages using Qt4 libraries. Requires EAPI=2.

case ${EAPI} in
	2|3|4) : ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

inherit base eutils multilib toolchain-funcs

export XDG_CONFIG_HOME="${T}"

# @ECLASS-VARIABLE: LANGS
# @DESCRIPTION:
# In case your Qt4 application provides various translations, use this variable
# to specify them in order to populate "linguas_*" IUSE automatically. Make sure
# that you set this variable BEFORE inheriting qt4-r2 eclass.
# example: LANGS="en el de"
for x in ${LANGS}; do
	IUSE="${IUSE} linguas_${x}"
done

# @ECLASS-VARIABLE: LANGSLONG
# @DESCRIPTION:
# Same as above, but this variable is for LINGUAS that must be in long format.
# Remember to set this variable BEFORE inheriting qt4-r2 eclass.
# Look at ${PORTDIR}/profiles/desc/linguas.desc for details.
for x in ${LANGSLONG}; do
	IUSE="${IUSE} linguas_${x%_*}"
done

# @FUNCTION: qt4-r2_src_unpack
# @DESCRIPTION:
# Default src_unpack function for packages that depend on qt4. If you have to
# override src_unpack in your ebuild (probably you don't need to), call
# qt4-r2_src_unpack in it.
qt4-r2_src_unpack() {
	debug-print-function $FUNCNAME "$@"
	base_src_unpack "$@"

	# Fallback to ${WORKDIR}/${MY_P} when ${WORKDIR}/${P} doesn't exist.
	# Feel free to re-implement this
	if [[ "${S}" == "${WORKDIR}/${P}" && ! -d ${S} && -d ${WORKDIR}/${MY_P} ]]; then
		ewarn "Falling back to '${WORKDIR}/${MY_P}'"
		S="${WORKDIR}/${MY_P}"
	fi
}

# @ECLASS-VARIABLE: PATCHES
# @DESCRIPTION:
# In case you have patches to apply, specify them in PATCHES variable. Make sure
# to specify the full path. This variable is used in src_prepare phase.
# example:
# PATCHES=( "${FILESDIR}"/mypatch.patch
# 	"${FILESDIR}"/mypatch2.patch )

# @FUNCTION: qt4-r2_src_prepare
# @DESCRIPTION:
# Default src_prepare function for packages that depend on qt4. If you have to
# override src_prepare in your ebuild, you should call qt4-r2_src_prepare in it,
# otherwise autopatcher will not work!
qt4-r2_src_prepare() {
	debug-print-function $FUNCNAME "$@"

	base_src_prepare "$@"
}

# @FUNCTION: qt4-r2_src_configure
# @DESCRIPTION:
# Default src_configure function for packages that depend on qt4. If you have to
# override src_configure in your ebuild, call qt4-r2_src_configure in it.
qt4-r2_src_configure() {
	debug-print-function $FUNCNAME "$@"

	local project_file="$(_find_project_file)"

	if [[ -n ${project_file} ]]; then
		eqmake4 ${project_file}
	else
		base_src_configure "$@"
	fi
}

# @FUNCTION: qt4-r2_src_compile
# @DESCRIPTION:
# Default src_compile function for packages that depend on qt4. If you have to
# override src_compile in your ebuild (probably you don't need to), call
# qt4-r2_src_compile in it.
qt4-r2_src_compile() {
	debug-print-function $FUNCNAME "$@"

	base_src_compile "$@"
}

# @ECLASS-VARIABLE: DOCS
# @DESCRIPTION:
# Use this variable if you want to install any documentation.
# example: DOCS="README AUTHORS"

# @ECLASS-VARIABLE: DOCSDIR
# @DESCRIPTION:
# Directory containing documentation. If not specified, ${S} will be used
# instead.

# @FUNCTION: qt4-r2_src_install
# @DESCRIPTION:
# Default src_install function for qt4-based packages. Installs compiled code,
# documentation (via DOCS variable) and translations (via LANGS and
# LANGSLONG variables).
qt4-r2_src_install() {
	debug-print-function $FUNCNAME "$@"

	emake INSTALL_ROOT="${D}" DESTDIR="${D}" install || die "emake install failed"

	# install documentation
	if [[ -n "${DOCS}" ]]; then
		local dir=${DOCSDIR:-${S}}
		for doc in ${DOCS}; do
			dodoc "${dir}/${doc}" || die "dodoc failed"
		done
	fi
}

# Internal function, used by eqmake4 and qt4-r2_src_configure
# Look for project files:
#   0 *.pro files found - output null string
#   1 *.pro file found - output its name
#   2 or more *.pro files found - if ${PN}.pro or $(basename ${S}).pro
#     are there, output any of them
# Outputs a project file argument used by eqmake4. Sets nullglob locally
# to avoid expanding *.pro as "*.pro" when there are no matching files.
_find_project_file() {
	shopt -s nullglob
	local pro_files=(*.pro)
	shopt -u nullglob
	local dir_name="$(basename ${S})"

	case ${#pro_files[@]} in
	1)
		echo "${pro_files[0]}"
		;;
	*)
		for pro_file in "${pro_files[@]}"; do
			if [[ "${pro_file}" == "${dir_name}" ||
				  "${pro_file}" == "${PN}.pro" ]]; then
				echo "${pro_file}"
				break
			fi
		done
		;;
	esac
}

# @FUNCTION: eqmake4
# @USAGE: [project file] [parameters to qmake]
# @DESCRIPTION:
# Wrapper for Qt4's qmake. If project file isn't specified eqmake4 will
# look for it in current directory (${S}, non-recursively). If more than
# one project file is found, the ${PN}.pro is processed, provided that it
# exists. Otherwise eqmake4 fails.
# All the arguments are appended unmodified to qmake command line. For
# recursive build systems, i.e. those based on the subdirs template, you
# should run eqmake4 on the top-level project file only, unless you have
# strong reasons to do things differently. During the building, qmake
# will be automatically re-invoked with the right arguments on every
# directory specified inside the top-level project file by the SUBDIRS
# variable.
eqmake4() {
	ebegin "Running qmake"

	local qmake_args=("$@")

	# check if project file was passed as a first argument
	# if not, then search for it
	local regexp='.*\.pro'
	if ! [[ "${1}" =~ ${regexp} ]]; then
		local project_file="$(_find_project_file)"
		if [[ -z "${project_file}" ]]; then
			echo
			eerror "No project file found in ${S}!"
			eerror "This shouldn't happen - please send a bug report to http://bugs.gentoo.org/"
			echo
			die "eqmake4 failed"
		fi
		qmake_args+=("${project_file}")
	fi

	# make sure CONFIG variable is correctly set for both release and debug builds
	local CONFIG_ADD="release"
	local CONFIG_REMOVE="debug"
	if has debug ${IUSE} && use debug; then
		CONFIG_ADD="debug"
		CONFIG_REMOVE="release"
	fi
	local awkscript='BEGIN {
				printf "### eqmake4 was here ###\n" > file;
				fixed=0;
			}
			/^[[:blank:]]*CONFIG[[:blank:]]*[\+\*]?=/ {
				for (i=1; i <= NF; i++) {
					if ($i ~ rem || $i ~ /debug_and_release/)
						{ $i=add; fixed=1; }
				}
			}
			/^[[:blank:]]*CONFIG[[:blank:]]*-=/ {
				for (i=1; i <= NF; i++) {
					if ($i ~ add) { $i=rem; fixed=1; }
				}
			}
			{
				print >> file;
			}
			END {
				printf "\nCONFIG -= debug_and_release %s\n", rem >> file;
				printf "CONFIG += %s\n", add >> file;
				print fixed;
			}'
	local file=
	while read file; do
		grep -q '^### eqmake4 was here ###$' "${file}" && continue
		local retval=$({
				rm -f "${file}" || echo "FAILED"
				awk -v file="${file}" -- "${awkscript}" add=${CONFIG_ADD} rem=${CONFIG_REMOVE} || echo "FAILED"
				} < "${file}")
		if [[ ${retval} == 1 ]]; then
			einfo " - fixed CONFIG in ${file}"
		elif [[ ${retval} != 0 ]]; then
			eerror "An error occurred while processing ${file}"
			die "eqmake4 failed to process '${file}'"
		fi
	done < <(find . -type f -name "*.pr[io]" -printf '%P\n' 2>/dev/null)

	[[ ${EAPI} == 2 ]] && use !prefix && EPREFIX=

	"${EPREFIX}"/usr/bin/qmake \
		-makefile \
		-config ${CONFIG_ADD} \
		QTDIR="${EPREFIX}"/usr/$(get_libdir) \
		QMAKE="${EPREFIX}"/usr/bin/qmake \
		QMAKE_CC="$(tc-getCC)" \
		QMAKE_CXX="$(tc-getCXX)" \
		QMAKE_LINK="$(tc-getCXX)" \
		QMAKE_CFLAGS_RELEASE="${CFLAGS}" \
		QMAKE_CFLAGS_DEBUG="${CFLAGS}" \
		QMAKE_CXXFLAGS_RELEASE="${CXXFLAGS}" \
		QMAKE_CXXFLAGS_DEBUG="${CXXFLAGS}" \
		QMAKE_LFLAGS_RELEASE="${LDFLAGS}" \
		QMAKE_LFLAGS_DEBUG="${LDFLAGS}" \
		QMAKE_LIBDIR_QT="${EPREFIX}"/usr/$(get_libdir)/qt4 \
		QMAKE_LIBDIR_X11="${EPREFIX}"/usr/$(get_libdir) \
		QMAKE_LIBDIR_OPENGL="${EPREFIX}"/usr/$(get_libdir) \
		QMAKE_STRIP= \
		"${qmake_args[@]}"

	# was qmake successful?
	if ! eend $? ; then
		echo
		eerror "Running qmake has failed! (see above for details)"
		eerror "This shouldn't happen - please send a bug report to http://bugs.gentoo.org/"
		echo
		die "eqmake4 failed"
	fi

	return 0
}

EXPORT_FUNCTIONS src_unpack src_prepare src_configure src_compile src_install
