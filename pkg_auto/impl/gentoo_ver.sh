# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @AUTHOR:
# Ulrich Müller <ulm@gentoo.org>
# Michał Górny <mgorny@gentoo.org>

# It is a cut-down and modified version of the now-gone eapi7-ver.eclass.

if [[ -z ${__GENTOO_VER_SH_INCLUDED__:-} ]]; then
__GENTOO_VER_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

VER_ERE_UNBOUNDED="([0-9]+(\.[0-9]+)*)([a-z]?)((_(alpha|beta|pre|rc|p)[0-9]*)*)(-r[0-9]+)?"
VER_ERE='^'"${VER_ERE_UNBOUNDED}"'$'

PKG_ERE_UNBOUNDED="[A-Za-z0-9_][A-Za-z0-9+_.-]*/[A-Za-z0-9_][A-Za-z0-9+_-]*"

# @FUNCTION: _ver_compare_int
# @USAGE: <a> <b>
# @RETURN: 0 if <a> -eq <b>, 1 if <a> -lt <b>, 3 if <a> -gt <b>
# @INTERNAL
# @DESCRIPTION:
# Compare two non-negative integers <a> and <b>, of arbitrary length.
# If <a> is equal to, less than, or greater than <b>, return 0, 1, or 3
# as exit status, respectively.
_ver_compare_int() {
	local a=$1 b=$2 d=$(( ${#1}-${#2} ))

	# Zero-pad to equal length if necessary.
	if [[ ${d} -gt 0 ]]; then
		printf -v b "%0${d}d%s" 0 "${b}"
	elif [[ ${d} -lt 0 ]]; then
		printf -v a "%0$(( -d ))d%s" 0 "${a}"
	fi

	[[ ${a} > ${b} ]] && return 3
	[[ ${a} == "${b}" ]]
}

# @FUNCTION: _ver_compare
# @USAGE: <va> <vb>
# @RETURN: 1 if <va> < <vb>, 2 if <va> = <vb>, 3 if <va> > <vb>
# @INTERNAL
# @DESCRIPTION:
# Compare two versions <va> and <vb>.  If <va> is less than, equal to,
# or greater than <vb>, return 1, 2, or 3 as exit status, respectively.
_ver_compare() {
	local va=${1} vb=${2} a an al as ar b bn bl bs br re LC_ALL=C

	re=${VER_ERE}

	[[ ${va} =~ ${re} ]] || fail "${FUNCNAME[0]}: invalid version: ${va}"
	an=${BASH_REMATCH[1]}
	al=${BASH_REMATCH[3]}
	as=${BASH_REMATCH[4]}
	ar=${BASH_REMATCH[7]}

	[[ ${vb} =~ ${re} ]] || fail "${FUNCNAME[0]}: invalid version: ${vb}"
	bn=${BASH_REMATCH[1]}
	bl=${BASH_REMATCH[3]}
	bs=${BASH_REMATCH[4]}
	br=${BASH_REMATCH[7]}

	# Compare numeric components (PMS algorithm 3.2)
	# First component
	_ver_compare_int "${an%%.*}" "${bn%%.*}" || return

	while [[ ${an} == *.* && ${bn} == *.* ]]; do
		# Other components (PMS algorithm 3.3)
		an=${an#*.}
		bn=${bn#*.}
		a=${an%%.*}
		b=${bn%%.*}
		if [[ ${a} == 0* || ${b} == 0* ]]; then
			# Remove any trailing zeros
			[[ ${a} =~ 0+$ ]] && a=${a%"${BASH_REMATCH[0]}"}
			[[ ${b} =~ 0+$ ]] && b=${b%"${BASH_REMATCH[0]}"}
			[[ ${a} > ${b} ]] && return 3
			[[ ${a} < ${b} ]] && return 1
		else
			_ver_compare_int "${a}" "${b}" || return
		fi
	done
	[[ ${an} == *.* ]] && return 3
	[[ ${bn} == *.* ]] && return 1

	# Compare letter components (PMS algorithm 3.4)
	[[ ${al} > ${bl} ]] && return 3
	[[ ${al} < ${bl} ]] && return 1

	# Compare suffixes (PMS algorithm 3.5)
	as=${as#_}${as:+_}
	bs=${bs#_}${bs:+_}
	while [[ -n ${as} && -n ${bs} ]]; do
		# Compare each suffix (PMS algorithm 3.6)
		a=${as%%_*}
		b=${bs%%_*}
		if [[ ${a%%[0-9]*} == "${b%%[0-9]*}" ]]; then
			_ver_compare_int "${a##*[a-z]}" "${b##*[a-z]}" || return
		else
			# Check for p first
			[[ ${a%%[0-9]*} == p ]] && return 3
			[[ ${b%%[0-9]*} == p ]] && return 1
			# Hack: Use that alpha < beta < pre < rc alphabetically
			[[ ${a} > ${b} ]] && return 3 || return 1
		fi
		as=${as#*_}
		bs=${bs#*_}
	done
	if [[ -n ${as} ]]; then
		[[ ${as} == p[_0-9]* ]] && return 3 || return 1
	elif [[ -n ${bs} ]]; then
		[[ ${bs} == p[_0-9]* ]] && return 1 || return 3
	fi

	# Compare revision components (PMS algorithm 3.7)
	_ver_compare_int "${ar#-r}" "${br#-r}" || return

	return 2
}

# @FUNCTION: ver_test
# @USAGE: [<v1>] <op> <v2>
# @DESCRIPTION:
# Check if the relation <v1> <op> <v2> is true.  If <v1> is not specified,
# default to ${PVR}.  <op> can be -gt, -ge, -eq, -ne, -le, -lt.
# Both versions must conform to the PMS version syntax (with optional
# revision parts), and the comparison is performed according to
# the algorithm specified in the PMS.
ver_test() {
	local va op vb

	if [[ $# -eq 3 ]]; then
		va=${1}
		shift
	else
		va=${PVR}
	fi

	[[ $# -eq 2 ]] || fail "${FUNCNAME[0]}: bad number of arguments"

	op=${1}
	vb=${2}

	case ${op} in
		-eq|-ne|-lt|-le|-gt|-ge) ;;
		*) fail "${FUNCNAME[0]}: invalid operator: ${op}" ;;
	esac

	_ver_compare "${va}" "${vb}"
	test $? "${op}" 2
}

# symbolic names for use with gentoo_ver_cmp_out
declare -gri GV_LT=1 GV_EQ=2 GV_GT=3

# Compare two versions. The result can be compared against GV_LT, GV_EQ and GV_GT variables.
#
# Params:
#
# 1 - version 1
# 2 - version 2
# 3 - name of variable to store the result in
function gentoo_ver_cmp_out() {
    local v1 v2
    v1=${1}; shift
    v2=${1}; shift
    local -n out_ref=${1}; shift

    out_ref=0
    _ver_compare "${v1}" "${v2}" || out_ref=${?}
    case ${out_ref} in
        "${GV_LT}"|"${GV_EQ}"|"${GV_GT}")
            return 0
            ;;
        *)
            fail "unexpected return value ${out_ref} from _ver_compare for ${v1} and ${v2}"
            ;;
    esac
}

function gentoo_ver_part_count() {
    local v=${1}; shift
    local -n part_count_ref=${1}; shift

    local -i count=1 idx len=${#v}
    for ((idx = 0; idx < len; ++idx)); do
        if [[ ${v:$idx:1} = '.' ]]; then
            ((++count))
        fi
    done
    part_count_ref=${count}
}

function gentoo_ver_truncate() {
    local v=${1}; shift
    local -i truncated_count=${1}; shift
    local -n out_v_ref=${1}; shift

    if [[ truncated_count -eq 0 ]]; then
        fail "truncated length must be 1 or more"
    fi

    local -i count=1 idx=0 len=${#v} truncated_len=0
    for ((idx = 0; idx < len; ++idx)); do
        ((++truncated_len))
        if [[ ${v:$idx:1} = '.' ]]; then
            ((++count))
            if [[ count -gt truncated_count ]]; then
                ((--truncated_len)) # remove the dot
                break
            fi
        fi
    done
    out_v_ref=${v:0:truncated_len}
}

declare_enum \
    GVD_NUMBERS_IDX \
    GVD_LETTER_IDX \
    GVD_SUFFICES_IDX \
    GVD_REVISION_IDX

function gentoo_ver_decomposed_declare() {
    struct_declare -ga "${@}" "( 'EMPTY_ARRAY' '' 'EMPTY_ARRAY' 0 )"
}

function gentoo_ver_decomposed_unset() {
    struct_unset \
        GVD_NUMBERS_IDX -a-- \
        GVD_SUFFICES_IDX -a-- \
        --- "${@}"
}

function decompose_gentoo_version() {
    local v=${1}; shift
    local gvd_var_name=${1}; shift

    local an al as ar
    [[ ${v} =~ ${VER_ERE} ]] || fail "${FUNCNAME[0]}: invalid version: ${v}"
    an=${BASH_REMATCH[1]}
    al=${BASH_REMATCH[3]}
    as=${BASH_REMATCH[4]}
    ar=${BASH_REMATCH[7]}

    local dgv_numbers_name
    gen_varname dgv_numbers_name
    declare -ga "${dgv_numbers_name}=()"
    read -r -a "${dgv_numbers_name}" <<<"${an//./ }"

    local dgv_suffices_name='EMPTY_ARRAY'
    if [[ -n ${as} ]]; then
        as=${as:1} # strip leading underline
        gen_varname dgv_suffices_name
        declare -ga "${dgv_suffices_name}=()"
        read -r -a "${dgv_suffices_name}" <<<"${as//_/ }"
    fi

    local -i rev=0
    if [[ -n ${ar} ]]; then
        rev=${ar#-r}
    fi

    assign_struct_members "${gvd_var_name}" \
                          GVD_NUMBERS_IDX "${dgv_numbers_name}" \
                          GVD_LETTER_IDX "${al}" \
                          GVD_SUFFICES_IDX "${dgv_suffices_name}" \
                          GVD_REVISION_IDX "${rev}"
}


fi
