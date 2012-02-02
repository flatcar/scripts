# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/bzr.eclass,v 1.8 2010/03/05 09:35:23 fauli Exp $
#
# @ECLASS: bzr.eclass
# @MAINTAINER:
# Jorge Manuel B. S. Vicetto <jmbsvicetto@gentoo.org>,
# Ulrich Mueller <ulm@gentoo.org>,
# Christian Faulhammer <fauli@gentoo.org>,
# Mark Lee <bzr-gentoo-overlay@lazymalevolence.com>,
# and anyone who wants to help
# @BLURB: This eclass provides support to use the Bazaar VCS
# @DESCRIPTION:
# The bzr.eclass provides support for apps using the Bazaar VCS
# (distributed version control system).
# The eclass was originally derived from the git eclass.
#
# Note: Just set EBZR_REPO_URI to the URI of the branch and the src_unpack()
# of this eclass will put an export of the branch in ${WORKDIR}/${PN}.

inherit eutils

EBZR="bzr.eclass"

case "${EAPI:-0}" in
	0|1) EXPORT_FUNCTIONS src_unpack ;;
	*)   EXPORT_FUNCTIONS src_unpack src_prepare ;;
esac

HOMEPAGE="http://bazaar-vcs.org/"
DESCRIPTION="Based on the ${EBZR} eclass"

DEPEND=">=dev-vcs/bzr-1.5"

# @ECLASS-VARIABLE: EBZR_STORE_DIR
# @DESCRIPTION:
# The directory to store all fetched Bazaar live sources.
: ${EBZR_STORE_DIR:=${PORTAGE_ACTUAL_DISTDIR-${DISTDIR}}/bzr-src}

# @ECLASS-VARIABLE: EBZR_FETCH_CMD
# @DESCRIPTION:
# The Bazaar command to fetch the sources.
EBZR_FETCH_CMD="bzr checkout --lightweight"

# @ECLASS-VARIABLE: EBZR_UPDATE_CMD
# @DESCRIPTION:
# The Bazaar command to update the sources.
EBZR_UPDATE_CMD="bzr update"

# @ECLASS-VARIABLE: EBZR_DIFF_CMD
# @DESCRIPTION:
# The Bazaar command to get the diff output.
EBZR_DIFF_CMD="bzr diff"

# @ECLASS-VARIABLE: EBZR_EXPORT_CMD
# @DESCRIPTION:
# The Bazaar command to export a branch.
EBZR_EXPORT_CMD="bzr export"

# @ECLASS-VARIABLE: EBZR_REVNO_CMD
# @DESCRIPTION:
# The Bazaar command to list a revision number of the branch.
EBZR_REVNO_CMD="bzr revno"

# @ECLASS-VARIABLE: EBZR_OPTIONS
# @DESCRIPTION:
# The options passed to the fetch and update commands.
EBZR_OPTIONS="${EBZR_OPTIONS:-}"

# @ECLASS-VARIABLE: EBZR_REPO_URI
# @DESCRIPTION:
# The repository URI for the source package.
#
# @CODE
# Supported protocols:
# 		- http://
# 		- https://
# 		- sftp://
# 		- rsync://
# 		- lp:
# @CODE
#
# Note: lp: seems to be an alias for https://launchpad.net
EBZR_REPO_URI="${EBZR_REPO_URI:-}"

# @ECLASS-VARIABLE: EBZR_BOOTSTRAP
# @DESCRIPTION:
# Bootstrap script or command like autogen.sh or etc.
EBZR_BOOTSTRAP="${EBZR_BOOTSTRAP:-}"

# @ECLASS-VARIABLE: EBZR_PATCHES
# @DESCRIPTION:
# bzr eclass can apply patches in bzr_bootstrap().
# You can use regular expressions in this variable like *.diff or
# *.patch and the like.
# NOTE: These patches will bei applied before EBZR_BOOTSTRAP is processed.
#
# Patches are searched both in ${PWD} and ${FILESDIR}, if not found in either
# location, the installation dies.
EBZR_PATCHES="${EBZR_PATCHES:-}"

# @ECLASS-VARIABLE: EBZR_REVISION
# @DESCRIPTION:
# Revision to fetch, defaults to the latest
# (see http://bazaar-vcs.org/BzrRevisionSpec or bzr help revisionspec).
# If you set this to a non-empty value, then it is recommended not to
# use a lightweight checkout (see also EBZR_FETCH_CMD).
EBZR_REVISION="${EBZR_REVISION:-}"

# @ECLASS-VARIABLE: EBZR_CACHE_DIR
# @DESCRIPTION:
# The directory to store the source for the package, relative to
# EBZR_STORE_DIR.
#
# default: ${PN}
EBZR_CACHE_DIR="${EBZR_CACHE_DIR:-${PN}}"

# @ECLASS-VARIABLE: EBZR_OFFLINE
# @DESCRIPTION:
# Set this variable to a non-empty value to disable the automatic updating of
# a bzr source tree. This is intended to be set outside the ebuild by users.
EBZR_OFFLINE="${EBZR_OFFLINE:-${ESCM_OFFLINE}}"

# @FUNCTION: bzr_initial_fetch
# @DESCRIPTION:
# Retrieves the source code from a repository for the first time, via
# ${EBZR_FETCH_CMD}.
bzr_initial_fetch() {
	local repository="${1}";
	local branch_dir="${2}";

	# fetch branch
	einfo "bzr fetch start -->"
	einfo "   repository: ${repository} => ${branch_dir}"

	${EBZR_FETCH_CMD} ${EBZR_OPTIONS} "${repository}" "${branch_dir}" \
		|| die "${EBZR}: can't branch from ${repository}."
}

# @FUNCTION: bzr_update
# @DESCRIPTION:
# Updates the source code from a repository, via ${EBZR_UPDATE_CMD}.
bzr_update() {
	local repository="${1}";

	if [[ -n "${EBZR_OFFLINE}" ]]; then
		einfo "skipping bzr update -->"
		einfo "   repository: ${repository}"
	else
		# update branch
		einfo "bzr update start -->"
		einfo "   repository: ${repository}"

		pushd "${EBZR_BRANCH_DIR}" > /dev/null
		${EBZR_UPDATE_CMD} ${EBZR_OPTIONS} \
			|| die "${EBZR}: can't update from ${repository}."
		popd > /dev/null
	fi
}

# @FUNCTION: bzr_fetch
# @DESCRIPTION:
# Wrapper function to fetch sources from a Bazaar repository via bzr
# fetch or bzr update, depending on whether there is an existing
# working copy in ${EBZR_BRANCH_DIR}.
bzr_fetch() {
	local EBZR_BRANCH_DIR

	# EBZR_REPO_URI is empty.
	[[ ${EBZR_REPO_URI} ]] || die "${EBZR}: EBZR_REPO_URI is empty."

	# check for the protocol or pull from a local repo.
	if [[ -z ${EBZR_REPO_URI%%:*} ]] ; then
		case ${EBZR_REPO_URI%%:*} in
			# lp: seems to be an alias to https://launchpad.net
			http|https|rsync|lp)
				;;
			sftp)
				if ! built_with_use --missing true dev-vcs/bzr sftp; then
					eerror "To fetch sources from ${EBZR_REPO_URI} you need SFTP"
					eerror "support in dev-vcs/bzr."
					die "Please, rebuild dev-vcs/bzr with the sftp USE flag enabled."
				fi
				;;
			*)
				die "${EBZR}: fetch from ${EBZR_REPO_URI%:*} is not yet implemented."
				;;
		esac
	fi

	if [[ ! -d ${EBZR_STORE_DIR} ]] ; then
		debug-print "${FUNCNAME}: initial branch. Creating bzr directory"
		local save_sandbox_write=${SANDBOX_WRITE}
		addwrite /
		mkdir -p "${EBZR_STORE_DIR}" \
			|| die "${EBZR}: can't mkdir ${EBZR_STORE_DIR}."
		SANDBOX_WRITE=${save_sandbox_write}
	fi

	pushd "${EBZR_STORE_DIR}" > /dev/null \
		|| die "${EBZR}: can't chdir to ${EBZR_STORE_DIR}"

	EBZR_BRANCH_DIR="${EBZR_STORE_DIR}/${EBZR_CACHE_DIR}"

	addwrite "${EBZR_STORE_DIR}"
	addwrite "${EBZR_BRANCH_DIR}"

	debug-print "${FUNCNAME}: EBZR_OPTIONS = ${EBZR_OPTIONS}"

	# Run bzr_initial_fetch() only if the branch has not been pulled
	# before or if the existing local copy is a full checkout (as did
	# an older version of bzr.eclass)
	if [[ ! -d ${EBZR_BRANCH_DIR} ]] ; then
		bzr_initial_fetch "${EBZR_REPO_URI}" "${EBZR_BRANCH_DIR}"
	elif [[ ${EBZR_FETCH_CMD} == *lightweight* \
		&& -d ${EBZR_BRANCH_DIR}/.bzr/repository ]]; then
		einfo "Re-fetching the branch to save space..."
		rm -rf "${EBZR_BRANCH_DIR}"
		bzr_initial_fetch "${EBZR_REPO_URI}" "${EBZR_BRANCH_DIR}"
	else
		bzr_update "${EBZR_REPO_URI}" "${EBZR_BRANCH_DIR}"
	fi

	cd "${EBZR_BRANCH_DIR}"

	einfo "exporting ..."

	if [[ -z ${EBZR_REVISION} ]]; then
		rsync -rlpgo --exclude=".bzr/" . "${WORKDIR}/${P}" \
			|| die "${EBZR}: export failed"
	else
		# revisions of a lightweight checkout are only available when online
		[[ -z ${EBZR_OFFLINE} || -d ${EBZR_BRANCH_DIR}/.bzr/repository ]] \
			|| die "${EBZR}: No support for revisions when off-line"
		${EBZR_EXPORT_CMD} -r "${EBZR_REVISION}" "${WORKDIR}/${P}" \
			|| die "${EBZR}: export failed"
	fi

	popd > /dev/null
}

# @FUNCTION: bzr_bootstrap
# @DESCRIPTION:
# Apply patches in ${EBZR_PATCHES} and run ${EBZR_BOOTSTRAP} if specified.
bzr_bootstrap() {
	local patch lpatch

	pushd "${S}" > /dev/null

	if [[ -n ${EBZR_PATCHES} ]] ; then
		einfo "apply patches -->"

		for patch in ${EBZR_PATCHES} ; do
			if [[ -f ${patch} ]] ; then
				epatch ${patch}
			else
				# This loop takes care of wildcarded patches given via
				# EBZR_PATCHES in an ebuild
				for lpatch in "${FILESDIR}"/${patch} ; do
					if [[ -f ${lpatch} ]] ; then
						epatch ${lpatch}
					else
						die "${EBZR}: ${patch} is not found"
					fi
				done
			fi
		done
	fi

	if [[ -n ${EBZR_BOOTSTRAP} ]] ; then
		einfo "begin bootstrap -->"

		if [[ -f ${EBZR_BOOTSTRAP} ]] && [[ -x ${EBZR_BOOTSTRAP} ]] ; then
			einfo "   bootstrap with a file: ${EBZR_BOOTSTRAP}"
			"./${EBZR_BOOTSTRAP}" \
				|| die "${EBZR}: can't execute EBZR_BOOTSTRAP."
		else
			einfo "   bootstrap with commands: ${EBZR_BOOTSTRAP}"
			"${EBZR_BOOTSTRAP}" \
				|| die "${EBZR}: can't eval EBZR_BOOTSTRAP."
		fi
	fi

	popd > /dev/null
}

# @FUNCTION: bzr_src_unpack
# @DESCRIPTION:
# Default src_unpack(). Includes bzr_fetch() and bootstrap().
bzr_src_unpack() {
	if ! [ -z ${EBZR_BRANCH} ]; then
		# This test will go away on 01 Jul 2010
		eerror "This ebuild uses EBZR_BRANCH which is not supported anymore"
		eerror "by the bzr.eclass.  Please report this to the ebuild's maintainer."
		die "EBZR_BRANCH still defined"
	fi
	bzr_fetch || die "${EBZR}: unknown problem in bzr_fetch()."
	case "${EAPI:-0}" in
		0|1) bzr_src_prepare ;;
	esac
}

# @FUNCTION: bzr_src_prepare
# @DESCRIPTION:
# Default src_prepare(). Executes bzr_bootstrap() for patch
# application and Make file generation (if needed).
bzr_src_prepare() {
	bzr_bootstrap || die "${EBZR}: unknown problem in bzr_bootstrap()."
}
