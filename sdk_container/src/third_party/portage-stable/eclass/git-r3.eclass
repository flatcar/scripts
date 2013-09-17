# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/git-r3.eclass,v 1.5 2013/09/13 15:08:37 mgorny Exp $

# @ECLASS: git-r3.eclass
# @MAINTAINER:
# Michał Górny <mgorny@gentoo.org>
# @BLURB: Eclass for fetching and unpacking git repositories.
# @DESCRIPTION:
# Third generation eclass for easing maitenance of live ebuilds using
# git as remote repository. The eclass supports lightweight (shallow)
# clones and bare clones of submodules.

case "${EAPI:-0}" in
	0|1|2|3|4|5)
		;;
	*)
		die "Unsupported EAPI=${EAPI} (unknown) for ${ECLASS}"
		;;
esac

if [[ ! ${_GIT_R3} ]]; then

inherit eutils

fi

EXPORT_FUNCTIONS src_unpack

if [[ ! ${_GIT_R3} ]]; then

# @ECLASS-VARIABLE: EGIT3_STORE_DIR
# @DESCRIPTION:
# Storage directory for git sources.
#
# EGIT3_STORE_DIR=${DISTDIR}/git3-src

# @ECLASS-VARIABLE: EGIT_REPO_URI
# @REQUIRED
# @DESCRIPTION:
# URIs to the repository, e.g. git://foo, https://foo. If multiple URIs
# are provided, the eclass will consider them as fallback URIs to try
# if the first URI does not work.
#
# It can be overriden via env using ${PN}_LIVE_REPO variable.
#
# Example:
# @CODE
# EGIT_REPO_URI="git://a/b.git https://c/d.git"
# @CODE

# @ECLASS-VARIABLE: EVCS_OFFLINE
# @DEFAULT_UNSET
# @DESCRIPTION:
# If non-empty, this variable prevents any online operations.

# @ECLASS-VARIABLE: EGIT_BRANCH
# @DEFAULT_UNSET
# @DESCRIPTION:
# The branch name to check out. If unset, the upstream default (HEAD)
# will be used.
#
# It can be overriden via env using ${PN}_LIVE_BRANCH variable.

# @ECLASS-VARIABLE: EGIT_COMMIT
# @DEFAULT_UNSET
# @DESCRIPTION:
# The tag name or commit identifier to check out. If unset, newest
# commit from the branch will be used. If set, EGIT_BRANCH will
# be ignored.
#
# It can be overriden via env using ${PN}_LIVE_COMMIT variable.

# @ECLASS-VARIABLE: EGIT_CHECKOUT_DIR
# @DESCRIPTION:
# The directory to check the git sources out to.
#
# EGIT_CHECKOUT_DIR=${WORKDIR}/${P}

# @ECLASS-VARIABLE: EGIT_NONSHALLOW
# @DEFAULT_UNSET
# @DESCRIPTION:
# Disable performing shallow fetches/clones. Shallow clones have
# a fair number of limitations. Therefore, if you'd like the eclass to
# perform complete clones instead, set this to a non-null value.
#
# This variable is to be set in make.conf. Ebuilds are not allowed
# to set it.

# @FUNCTION: _git-r3_env_setup
# @INTERNAL
# @DESCRIPTION:
# Set the eclass variables as necessary for operation. This can involve
# setting EGIT_* to defaults or ${PN}_LIVE_* variables.
_git-r3_env_setup() {
	debug-print-function ${FUNCNAME} "$@"

	local esc_pn livevar
	esc_pn=${PN//[-+]/_}

	livevar=${esc_pn}_LIVE_REPO
	EGIT_REPO_URI=${!livevar:-${EGIT_REPO_URI}}
	[[ ${!livevar} ]] \
		&& ewarn "Using ${livevar}, no support will be provided"

	livevar=${esc_pn}_LIVE_BRANCH
	EGIT_BRANCH=${!livevar:-${EGIT_BRANCH}}
	[[ ${!livevar} ]] \
		&& ewarn "Using ${livevar}, no support will be provided"

	livevar=${esc_pn}_LIVE_COMMIT
	EGIT_COMMIT=${!livevar:-${EGIT_COMMIT}}
	[[ ${!livevar} ]] \
		&& ewarn "Using ${livevar}, no support will be provided"

	# Migration helpers. Remove them when git-2 is removed.

	if [[ ${EGIT_SOURCEDIR} ]]; then
		eerror "EGIT_SOURCEDIR has been replaced by EGIT_CHECKOUT_DIR. While updating"
		eerror "your ebuild, please check whether the variable is necessary at all"
		eerror "since the default has been changed from \${S} to \${WORKDIR}/\${P}."
		eerror "Therefore, proper setting of S may be sufficient."
		die "EGIT_SOURCEDIR has been replaced by EGIT_CHECKOUT_DIR."
	fi

	if [[ ${EGIT_MASTER} ]]; then
		eerror "EGIT_MASTER has been removed. Instead, the upstream default (HEAD)"
		eerror "is used by the eclass. Please remove the assignment or use EGIT_BRANCH"
		eerror "as necessary."
		die "EGIT_MASTER has been removed."
	fi

	if [[ ${EGIT_HAS_SUBMODULES} ]]; then
		eerror "EGIT_HAS_SUBMODULES has been removed. The eclass no longer needs"
		eerror "to switch the clone type in order to support submodules and therefore"
		eerror "submodules are detected and fetched automatically."
		die "EGIT_HAS_SUBMODULES is no longer necessary."
	fi

	if [[ ${EGIT_PROJECT} ]]; then
		eerror "EGIT_PROJECT has been removed. Instead, the eclass determines"
		eerror "the local clone path using path in canonical EGIT_REPO_URI."
		eerror "If the current algorithm causes issues for you, please report a bug."
		die "EGIT_PROJECT is no longer necessary."
	fi

	if [[ ${EGIT_BOOTSTRAP} ]]; then
		eerror "EGIT_BOOTSTRAP has been removed. Please create proper src_prepare()"
		eerror "instead."
		die "EGIT_BOOTSTRAP has been removed."
	fi

	if [[ ${EGIT_NOUNPACK} ]]; then
		eerror "EGIT_NOUNPACK has been removed. The eclass no longer calls default"
		eerror "unpack function. If necessary, please declare proper src_unpack()."
		die "EGIT_NOUNPACK has been removed."
	fi
}

# @FUNCTION: _git-r3_set_gitdir
# @USAGE: <repo-uri>
# @INTERNAL
# @DESCRIPTION:
# Obtain the local repository path and set it as GIT_DIR. Creates
# a new repository if necessary.
#
# <repo-uri> may be used to compose the path. It should therefore be
# a canonical URI to the repository.
_git-r3_set_gitdir() {
	debug-print-function ${FUNCNAME} "$@"

	local repo_name=${1#*://*/}

	# strip common prefixes to make paths more likely to match
	# e.g. git://X/Y.git vs https://X/git/Y.git
	# (but just one of the prefixes)
	case "${repo_name}" in
		# cgit can proxy requests to git
		cgit/*) repo_name=${repo_name#cgit/};;
		# pretty common
		git/*) repo_name=${repo_name#git/};;
		# gentoo.org
		gitroot/*) repo_name=${repo_name#gitroot/};;
		# google code, sourceforge
		p/*) repo_name=${repo_name#p/};;
		# kernel.org
		pub/scm/*) repo_name=${repo_name#pub/scm/};;
	esac
	# ensure a .git suffix, same reason
	repo_name=${repo_name%.git}.git
	# now replace all the slashes
	repo_name=${repo_name//\//_}

	local distdir=${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}
	: ${EGIT3_STORE_DIR:=${distdir}/git3-src}

	GIT_DIR=${EGIT3_STORE_DIR}/${repo_name}

	if [[ ! -d ${EGIT3_STORE_DIR} ]]; then
		(
			addwrite /
			mkdir -m0755 -p "${EGIT3_STORE_DIR}"
		) || die "Unable to create ${EGIT3_STORE_DIR}"
	fi

	addwrite "${EGIT3_STORE_DIR}"
	if [[ ! -d ${GIT_DIR} ]]; then
		mkdir "${GIT_DIR}" || die
		git init --bare || die

		# avoid auto-unshallow :)
		touch "${GIT_DIR}"/shallow || die
	fi
}

# @FUNCTION: _git-r3_set_submodules
# @USAGE: <file-contents>
# @INTERNAL
# @DESCRIPTION:
# Parse .gitmodules contents passed as <file-contents>
# as in "$(cat .gitmodules)"). Composes a 'submodules' array that
# contains in order (name, URL, path) for each submodule.
_git-r3_set_submodules() {
	debug-print-function ${FUNCNAME} "$@"

	local data=${1}

	# ( name url path ... )
	submodules=()

	local l
	while read l; do
		# submodule.<path>.path=<path>
		# submodule.<path>.url=<url>
		[[ ${l} == submodule.*.url=* ]] || continue

		l=${l#submodule.}
		local subname=${l%%.url=*}

		submodules+=(
			"${subname}"
			"$(echo "${data}" | git config -f /dev/fd/0 \
				submodule."${subname}".url)"
			"$(echo "${data}" | git config -f /dev/fd/0 \
				submodule."${subname}".path)"
		)
	done < <(echo "${data}" | git config -f /dev/fd/0 -l)
}

# @FUNCTION: _git-r3_smart_fetch
# @USAGE: <git-fetch-args>...
# @DESCRIPTION:
# Try fetching without '--depth' and switch to '--depth 1' if that
# will involve less objects fetched.
_git-r3_smart_fetch() {
	debug-print-function ${FUNCNAME} "$@"

	local sed_regexp='.*Counting objects: \([0-9]*\), done\..*'

	# start the main fetch
	local cmd=( git fetch --progress "${@}" )
	echo "${cmd[@]}" >&2

	# we copy the output to the 'sed' pipe for parsing. whenever sed finds
	# the process count, it quits quickly to avoid delays in writing it.
	# then, we start a dummy 'cat' to keep the pipe alive

	"${cmd[@]}" 2>&1 \
		| tee >(
			sed -n -e "/${sed_regexp}/{s/${sed_regexp}/\1/p;q}" \
				> "${T}"/git-r3_main.count
			exec cat >/dev/null
		) &
	local main_pid=${!}

	# start the helper process
	_git-r3_sub_fetch() {
		# wait for main fetch to get object count; if the server doesn't
		# output it, we won't even launch the parallel process
		while [[ ! -s ${T}/git-r3_main.count ]]; do
			sleep 0.25
		done

		# ok, let's see if parallel fetch gives us smaller count
		# --dry-run will prevent it from writing to the local clone
		# and sed should terminate git with SIGPIPE
		local sub_count=$(git fetch --progress --dry-run --depth 1 "${@}" 2>&1 \
			| sed -n -e "/${sed_regexp}/{s/${sed_regexp}/\1/p;q}")
		local main_count=$(<"${T}"/git-r3_main.count)

		# let's be real sure that '--depth 1' will be good for us.
		# note that we have purely objects counts, and '--depth 1'
		# may involve much bigger objects
		if [[ ${main_count} && ${main_count} -ge $(( sub_count * 3/2 )) ]]
		then
			# signal that we want shallow fetch instead,
			# and terminate the non-shallow fetch process
			touch "${T}"/git-r3_want_shallow || die
			kill ${main_pid} &>/dev/null
			exit 0
		fi

		exit 1
	}
	_git-r3_sub_fetch "${@}" &
	local sub_pid=${!}

	# wait for main process to terminate, either of its own
	# or by signal from subprocess
	wait ${main_pid}
	local main_ret=${?}

	# wait for subprocess to terminate, killing it if necessary.
	# if main fetch finished before it, there's no point in keeping
	# it alive. if main fetch was killed by it, it's done anyway
	kill ${sub_pid} &>/dev/null
	wait ${sub_pid}

	# now see if subprocess wanted to tell us something...
	if [[ -f ${T}/git-r3_want_shallow ]]; then
		rm "${T}"/git-r3_want_shallow || die

		# if fetch finished already (wasn't killed), ignore it
		[[ ${main_ret} -eq 0 ]] && return 0

		# otherwise, restart as shallow fetch
		einfo "Restarting fetch using --depth 1 to save bandwidth ..."
		local cmd=( git fetch --progress --depth 1 "${@}" )
		echo "${cmd[@]}" >&2
		"${cmd[@]}"
		main_ret=${?}
	fi

	return ${main_ret}
}

# @FUNCTION: git-r3_fetch
# @USAGE: [<repo-uri> [<remote-ref> [<local-id>]]]
# @DESCRIPTION:
# Fetch new commits to the local clone of repository.
#
# <repo-uri> specifies the repository URIs to fetch from, as a space-
# -separated list. The first URI will be used as repository group
# identifier and therefore must be used consistently. When not
# specified, defaults to ${EGIT_REPO_URI}.
#
# <remote-ref> specifies the remote ref or commit id to fetch.
# It is preferred to use 'refs/heads/<branch-name>' for branches
# and 'refs/tags/<tag-name>' for tags. Other options are 'HEAD'
# for upstream default branch and hexadecimal commit SHA1. Defaults
# to the first of EGIT_COMMIT, EGIT_BRANCH or literal 'HEAD' that
# is set to a non-null value.
#
# <local-id> specifies the local branch identifier that will be used to
# locally store the fetch result. It should be unique to multiple
# fetches within the repository that can be performed at the same time
# (including parallel merges). It defaults to ${CATEGORY}/${PN}/${SLOT}.
# This default should be fine unless you are fetching multiple trees
# from the same repository in the same ebuild.
#
# The fetch operation will affect the EGIT_STORE only. It will not touch
# the working copy, nor export any environment variables.
# If the repository contains submodules, they will be fetched
# recursively.
git-r3_fetch() {
	debug-print-function ${FUNCNAME} "$@"

	local repos=( ${1:-${EGIT_REPO_URI}} )
	local branch=${EGIT_BRANCH:+refs/heads/${EGIT_BRANCH}}
	local remote_ref=${2:-${EGIT_COMMIT:-${branch:-HEAD}}}
	local local_id=${3:-${CATEGORY}/${PN}/${SLOT}}
	local local_ref=refs/heads/${local_id}/__main__

	[[ ${repos[@]} ]] || die "No URI provided and EGIT_REPO_URI unset"

	local -x GIT_DIR
	_git-r3_set_gitdir ${repos[0]}

	# try to fetch from the remote
	local r success
	for r in ${repos[@]}; do
		einfo "Fetching ${remote_ref} from ${r} ..."

		local is_branch lookup_ref
		if [[ ${remote_ref} == refs/heads/* || ${remote_ref} == HEAD ]]
		then
			is_branch=1
			lookup_ref=${remote_ref}
		else
			# ls-remote by commit is going to fail anyway,
			# so we may as well pass refs/tags/ABCDEF...
			lookup_ref=refs/tags/${remote_ref}
		fi

		# first, try ls-remote to see if ${remote_ref} is a real ref
		# and not a commit id. if it succeeds, we can pass ${remote_ref}
		# to 'fetch'. otherwise, we will just fetch everything

		# split on whitespace
		local ref=(
			$(git ls-remote "${r}" "${lookup_ref}" || echo __FAIL__)
		)

		# normally, ref[0] is a hash, so we can do magic strings here
		[[ ${ref[0]} == __FAIL__ ]] && continue

		local nonshallow=${EGIT_NONSHALLOW}
		local ref_param=()
		if [[ ! ${ref[0]} ]]; then
			nonshallow=1
		fi

		# 1. if we need a non-shallow clone and we have a shallow one,
		#    we need to unshallow it explicitly.
		# 2. if we want a shallow clone, we just pass '--depth 1'
		#    to the first fetch in the repo. passing '--depth'
		#    to further requests usually results in more data being
		#    downloaded than without it.
		# 3. if we update a shallow clone, we try without '--depth'
		#    first since that usually transfers less data. however,
		#    we use git-r3_smart_fetch that can switch into '--depth 1'
		#    if that looks beneficial.

		local fetch_command=( git fetch )
		if [[ ${nonshallow} ]]; then
			if [[ -f ${GIT_DIR}/shallow ]]; then
				ref_param+=( --unshallow )
			fi
		else
			# 'git show-ref --heads' returns 1 when there are no branches
			if ! git show-ref --heads -q; then
				ref_param+=( --depth 1 )
			else
				fetch_command=( _git-r3_smart_fetch )
			fi
		fi

		# now, another important thing. we may only fetch a remote
		# branch directly to a local branch. Otherwise, we need to fetch
		# the commit and re-create the branch on top of it.

		if [[ ${ref[0]} ]]; then
			if [[ ${is_branch} ]]; then
				ref_param+=( -f "${remote_ref}:${local_id}/__main__" )
			else
				ref_param+=( "refs/tags/${remote_ref}" )
			fi
		fi

		# if ${remote_ref} is branch or tag, ${ref[@]} will contain
		# the respective commit id. otherwise, it will be an empty
		# array, so the following won't evaluate to a parameter.
		set -- "${fetch_command[@]}" --no-tags "${r}" "${ref_param[@]}"
		echo "${@}" >&2
		if "${@}"; then
			if [[ ! ${is_branch} ]]; then
				set -- git branch -f "${local_id}/__main__" \
					"${ref[0]:-${remote_ref}}"
				echo "${@}" >&2
				if ! "${@}"; then
					die "Creating branch for ${remote_ref} failed (wrong ref?)."
				fi
			fi

			success=1
			break
		fi
	done
	[[ ${success} ]] || die "Unable to fetch from any of EGIT_REPO_URI"

	# recursively fetch submodules
	if git cat-file -e "${local_ref}":.gitmodules &>/dev/null; then
		local submodules
		_git-r3_set_submodules \
			"$(git cat-file -p "${local_ref}":.gitmodules || die)"

		while [[ ${submodules[@]} ]]; do
			local subname=${submodules[0]}
			local url=${submodules[1]}
			local path=${submodules[2]}
			local commit=$(git rev-parse "${local_ref}:${path}")

			if [[ ! ${commit} ]]; then
				die "Unable to get commit id for submodule ${subname}"
			fi

			git-r3_fetch "${url}" "${commit}" "${local_id}/${subname}"

			submodules=( "${submodules[@]:3}" ) # shift
		done
	fi
}

# @FUNCTION: git-r3_checkout
# @USAGE: [<repo-uri> [<checkout-path> [<local-id>]]]
# @DESCRIPTION:
# Check the previously fetched tree to the working copy.
#
# <repo-uri> specifies the repository URIs, as a space-separated list.
# The first URI will be used as repository group identifier
# and therefore must be used consistently with git-r3_fetch.
# The remaining URIs are not used and therefore may be omitted.
# When not specified, defaults to ${EGIT_REPO_URI}.
#
# <checkout-path> specifies the path to place the checkout. It defaults
# to ${EGIT_CHECKOUT_DIR} if set, otherwise to ${WORKDIR}/${P}.
#
# <local-id> needs to specify the local identifier that was used
# for respective git-r3_fetch.
#
# The checkout operation will write to the working copy, and export
# the repository state into the environment. If the repository contains
# submodules, they will be checked out recursively.
git-r3_checkout() {
	debug-print-function ${FUNCNAME} "$@"

	local repos=( ${1:-${EGIT_REPO_URI}} )
	local out_dir=${2:-${EGIT_CHECKOUT_DIR:-${WORKDIR}/${P}}}
	local local_id=${3:-${CATEGORY}/${PN}/${SLOT}}

	local -x GIT_DIR GIT_WORK_TREE
	_git-r3_set_gitdir ${repos[0]}
	GIT_WORK_TREE=${out_dir}
	mkdir -p "${GIT_WORK_TREE}"

	einfo "Checking out ${repos[0]} to ${out_dir} ..."

	if ! git cat-file -e refs/heads/"${local_id}"/__main__
	then
		if [[ ${EVCS_OFFLINE} ]]; then
			die "No local clone of ${repos[0]}. Unable to work with EVCS_OFFLINE."
		else
			die "Logic error: no local clone of ${repos[0]}. git-r3_fetch not used?"
		fi
	fi

	set -- git checkout -f "${local_id}"/__main__ .
	echo "${@}" >&2
	"${@}" || die "git checkout ${local_id}/__main__ failed"

	# diff against previous revision (if any)
	local new_commit_id=$(git rev-parse --verify "${local_id}"/__main__)
	local old_commit_id=$(
		git rev-parse --verify "${local_id}"/__old__ 2>/dev/null
	)

	if [[ ! ${old_commit_id} ]]; then
		echo "GIT NEW branch -->"
		echo "   repository:               ${repos[0]}"
		echo "   at the commit:            ${new_commit_id}"
	else
		echo "GIT update -->"
		echo "   repository:               ${repos[0]}"
		# write out message based on the revisions
		if [[ "${old_commit_id}" != "${new_commit_id}" ]]; then
			echo "   updating from commit:     ${old_commit_id}"
			echo "   to commit:                ${new_commit_id}"

			git --no-pager diff --stat \
				${old_commit_id}..${new_commit_id}
		else
			echo "   at the commit:            ${new_commit_id}"
		fi
	fi
	git branch -f "${local_id}"/{__old__,__main__} || die

	# recursively checkout submodules
	if [[ -f ${GIT_WORK_TREE}/.gitmodules ]]; then
		local submodules
		_git-r3_set_submodules \
			"$(<"${GIT_WORK_TREE}"/.gitmodules)"

		while [[ ${submodules[@]} ]]; do
			local subname=${submodules[0]}
			local url=${submodules[1]}
			local path=${submodules[2]}

			git-r3_checkout "${url}" "${GIT_WORK_TREE}/${path}" \
				"${local_id}/${subname}"

			submodules=( "${submodules[@]:3}" ) # shift
		done
	fi

	# keep this *after* submodules
	export EGIT_DIR=${GIT_DIR}
	export EGIT_VERSION=${new_commit_id}
}

# @FUNCTION: git-r3_peek_remote_ref
# @USAGE: [<repo-uri> [<remote-ref>]]
# @DESCRIPTION:
# Peek the reference in the remote repository and print the matching
# (newest) commit SHA1.
#
# <repo-uri> specifies the repository URIs to fetch from, as a space-
# -separated list. When not specified, defaults to ${EGIT_REPO_URI}.
#
# <remote-ref> specifies the remote ref to peek.  It is preferred to use
# 'refs/heads/<branch-name>' for branches and 'refs/tags/<tag-name>'
# for tags. Alternatively, 'HEAD' may be used for upstream default
# branch. Defaults to the first of EGIT_COMMIT, EGIT_BRANCH or literal
# 'HEAD' that is set to a non-null value.
#
# The operation will be done purely on the remote, without using local
# storage. If commit SHA1 is provided as <remote-ref>, the function will
# fail due to limitations of git protocol.
#
# On success, the function returns 0 and writes hexadecimal commit SHA1
# to stdout. On failure, the function returns 1.
git-r3_peek_remote_ref() {
	debug-print-function ${FUNCNAME} "$@"

	local repos=( ${1:-${EGIT_REPO_URI}} )
	local branch=${EGIT_BRANCH:+refs/heads/${EGIT_BRANCH}}
	local remote_ref=${2:-${EGIT_COMMIT:-${branch:-HEAD}}}

	[[ ${repos[@]} ]] || die "No URI provided and EGIT_REPO_URI unset"

	local r success
	for r in ${repos[@]}; do
		einfo "Peeking ${remote_ref} on ${r} ..." >&2

		local is_branch lookup_ref
		if [[ ${remote_ref} == refs/heads/* || ${remote_ref} == HEAD ]]
		then
			is_branch=1
			lookup_ref=${remote_ref}
		else
			# ls-remote by commit is going to fail anyway,
			# so we may as well pass refs/tags/ABCDEF...
			lookup_ref=refs/tags/${remote_ref}
		fi

		# split on whitespace
		local ref=(
			$(git ls-remote "${r}" "${lookup_ref}")
		)

		if [[ ${ref[0]} ]]; then
			echo "${ref[0]}"
			return 0
		fi
	done

	return 1
}

git-r3_src_fetch() {
	debug-print-function ${FUNCNAME} "$@"

	[[ ${EVCS_OFFLINE} ]] && return

	if [[ ! ${EGIT3_STORE_DIR} && ${EGIT_STORE_DIR} ]]; then
		ewarn "You have set EGIT_STORE_DIR but not EGIT3_STORE_DIR. Please consider"
		ewarn "setting EGIT3_STORE_DIR for git-r3.eclass. It is recommended to use"
		ewarn "a different directory than EGIT_STORE_DIR to ease removing old clones"
		ewarn "when git-2 eclass becomes deprecated."
	fi

	_git-r3_env_setup
	git-r3_fetch
}

git-r3_src_unpack() {
	debug-print-function ${FUNCNAME} "$@"

	_git-r3_env_setup
	git-r3_src_fetch
	git-r3_checkout
}

# https://bugs.gentoo.org/show_bug.cgi?id=482666
git-r3_pkg_outofdate() {
	debug-print-function ${FUNCNAME} "$@"

	local new_commit_id=$(git-r3_peek_remote_ref)
	ewarn "old: ${EGIT_VERSION}"
	ewarn "new: ${new_commit_id}"
	[[ ${new_commit_id} && ${old_commit_id} ]] || return 2

	[[ ${EGIT_VERSION} != ${new_commit_id} ]]
}

_GIT_R3=1
fi
