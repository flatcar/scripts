#!/bin/bash

if [[ -z ${__MD5_CACHE_LIB_SH_INCLUDED__:-} ]]; then
__MD5_CACHE_LIB_SH_INCLUDED__=x

function __mcl_gen_varname_full() {
    local -n name=${1}; shift
    local prefix=${1}; shift
    local -n counter=${1}; shift

    name=${prefix}_${counter}
    counter=$((counter + 1))
}

function __mcl_gen_varname() {
    local name=${1}; shift
    local prefix=${1}; shift

    local counter_name="${prefix}_COUNTER"

    __mcl_gen_varname_full "${name}" "${prefix}" "${counter_name}"
}

function __mcl_declare() {
    local -a declare_opts=()

    while [[ ${#} -gt 0 ]]; do
        case ${1} in
            --)
                shift
                break
                ;;
            -*)
                declare_opts+=( "${1}" )
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    local name=${1}; shift
    local definition=${1}; shift

    declare "${declare_opts[@]}" "${name}=${definition}"
}

# use requirement
#
# n - name of USE flag
# m - mode: +, =, !=, ?, !?, - (+ enabled, = strict relation, != reverted strict relation, ? enabled if enabled, !? disabled if disabled, - disabled)
# p - pretend: empty, + or - (+ pretend enabled if missing, - pretend disabled if missing)

# shellcheck disable=SC2034 # used indirectly through __mcl_gen_varname
declare -i UR_COUNTER=0

function ur_gen_varname() {
    __mcl_gen_varname "${1}" UR
}

function ur_declare() {
    __mcl_declare -g -A "${@}" "( [n]=ITS_UNSET [m]=+ [p]= )"
}

function ur_unset() {
    unset "${1}"
}

# package depedency specification
#
# b - blocks: 0, 1, 2 (0 - no block, 1 - weak, 2 - strong)
# o - operator: empty or some op (< <= = ~ >= >)
# n - name: category/package
# v - version: empty or version without the leading dash
# s - slot: empty or slot operator without the leading colon
# u - use requirements: name of an array variable containing use requirements

declare -ri PDS_NO_BLOCK=0
declare -ri PDS_WEAK_BLOCK=1
declare -ri PDS_STRONG_BLOCK=2
# shellcheck disable=SC2034 # used indirectly through __mcl_gen_varname
declare -i PDS_COUNTER=0
# shellcheck disable=SC2034 # used by name
declare -ra EMPTY_ARRAY=()

function pds_gen_varname() {
    __mcl_gen_varname "${1}" PDS
}

function pds_declare() {
    __mcl_declare -g -A "${@}" "( [b]=${PDS_NO_BLOCK} [o]= [n]=ITS_UNSET [v]= [s]= [u]=EMPTY_ARRAY )"
}

function pds_unset() {
    local name=${1}; shift

    local -n pds=${name}
    local use_reqs_name=${pds['u']}

    local -n use_reqs=${use_reqs_name}
    local ur_name
    for ur_name in "${use_reqs[@]}"; do
        ur_unset "${ur_name}"
    done

    if [[ ${use_reqs_name} != 'EMPTY_ARRAY' ]]; then
        unset "${use_reqs_name}"
    fi

    unset "${name}"
}

# shellcheck disable=SC2034 # used indirectly through __mcl_gen_varname
declare -i UR_ARRAY_COUNTER=0

function pds_add_urs() {
    local -n pds=${1}; shift
    # rest are use requirements

    local use_reqs_name=${pds['u']}
    if [[ ${use_reqs_name} = 'EMPTY_ARRAY' ]]; then
        local ura_name
        __mcl_gen_varname ura_name UR_ARRAY
        declare -g -a "${ura_name}"
        pds['u']=${ura_name}
        use_reqs_name=${ura_name}
        unset ura_name
    fi

    local -n use_reqs=${use_reqs_name}
    use_reqs+=( "${@}" )
}

# group
# t - type, 0 or 1 (0 - all of, 1, any of)
# u - use name or empty, must be empty for "any of" type
# d - enabled use, 0 or 1 (0 - enabled, 1 - disabled), only valid if use name is not empty
# i - items: name of an array variable containing items

declare -ri GROUP_ALL_OF=0
declare -ri GROUP_ANY_OF=1
declare -ri GROUP_USE_ENABLED=0
declare -ri GROUP_USE_DISABLED=1
# shellcheck disable=SC2034 # used indirectly through __mcl_gen_varname
declare -i GROUP_COUNTER=0

function group_gen_varname() {
    __mcl_gen_varname "${1}" GROUP
}

function group_declare() {
    __mcl_declare -g -A "${@}" "( [t]=${GROUP_ALL_OF} [u]= [d]=${GROUP_USE_ENABLED} [i]=EMPTY_ARRAY )"
}

group_declare -r EMPTY_GROUP

function group_unset() {
    local name=${1}; shift

    local -n group=${name}
    local items_name=${group['i']}

    local -n items=${items_name}
    local i
    for i in "${items[@]}"; do
        item_unset "${i}"
    done

    if [[ ${items_name} != 'EMPTY_ARRAY' ]]; then
        unset "${items_name}"
    fi

    if [[ ${name} != 'EMPTY_GROUP' ]]; then
        unset "${name}"
    fi
}

# shellcheck disable=SC2034 # used indirectly through __mcl_gen_varname
declare -i ITEM_ARRAY_COUNTER=0

function group_add_item() {
    local -n group=${1}; shift
    local item=${1}; shift

    local items_name=${group['i']}
    if [[ ${items_name} = 'EMPTY_ARRAY' ]]; then
        local ia_name
        __mcl_gen_varname ia_name ITEM_ARRAY
        declare -g -a "${ia_name}"
        group['i']=${ia_name}
        items_name=${ia_name}
        unset ia_name
    fi

    local -n items=${items_name}
    items+=( "${item}" )
}

# item
# a string of <mode>:<name>
# mode - e, g, l, p (e - empty, g - group, l - license, p - pds)
# name - variable name holding the stuff described by mode
# shellcheck disable=SC2034 # used indirectly through __mcl_gen_varname
declare -i ITEM_COUNTER=0

function item_gen_varname() {
    __mcl_gen_varname "${1}" ITEM
}

function item_declare() {
    __mcl_declare -g "${@}" 'e:'
}

function item_unset() {
    local name=${1}; shift
    local -n item=${name}

    case ${item} in
        e:*)
            # noop
            :
            ;;
        g:*)
            group_unset "${name#*:}"
            ;;
        l:*)
            # noop, license is just a string
            ;;
        p:*)
            pds_unset "${name#*:}"
            ;;
    esac

    unset "${name}"
}

declare -ri DSF_DEPEND=0
declare -ri DSF_LICENSE=1

# possible items:
# <block>\?<category>/<name>\(:<slot>\)\? (only in depends)
# <block>\?<operator><category>/<name>-<version>\(:<slot>\)\? (only in depends)
# <license> (only in licenses)
# ( item\+ )
# || ( item\+ )
# !\?use? ( item\+ )
function parse_dsf() {
    local dsf_type=${1}; shift
    local dep=${1}; shift
    local -n top_group_name=${1}; shift

    local -a group_stack
    local pd_group pd_item pd_group_created='' pd_pds

    group_gen_varname pd_group
    group_declare "${pd_group}"
    group_stack+=( "${pd_group}" )

    local -a tokens
    mapfile -t tokens <<<"${dep// /$'\n'}"

    local token
    for token in "${tokens[@]}"; do
        if [[ ${token} = '||' ]]; then
            # "any of" group, so create the group, make it an item, add
            # to current group and mark the new group as current
            group_gen_varname pd_group
            group_declare "${pd_group}"
            # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays/maps
            local -n g=${pd_group}
            g['t']=${GROUP_ANY_OF}
            unset -n g

            item_gen_varname pd_item
            item_declare "${pd_item}"
            local -n i=${pd_item}
            i="g:${pd_group}"
            unset -n i

            group_add_item "${group_stack[-1]}" "${pd_item}"

            group_stack+=( "${pd_group}" )
            pd_group_created=x
        elif [[ ${token} =~ ^!?[A-Za-z0-9][A-Za-z0-9+_-]*\?$ ]]; then
            # "use" group, so create the group, make it an item, add
            # to current group and mark the new group as current
            local disabled=${GROUP_USE_ENABLED} use=${token%?}

            if [[ ${use} = '!'* ]]; then
                disabled=${GROUP_USE_DISABLED}
                use=${use:1}
            fi

            group_gen_varname pd_group
            group_declare "${pd_group}"
            # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays/maps
            local -n g=${pd_group}
            g['t']=${GROUP_ALL_OF}
            g['u']=${use}
            # shellcheck disable=SC2034 # it is used indirectly elsewhere
            g['d']=${disabled}
            unset -n g

            unset use disabled

            item_gen_varname pd_item
            item_declare "${pd_item}"
            local -n i=${pd_item}
            i="g:${pd_group}"
            unset -n i

            group_add_item "${group_stack[-1]}" "${pd_item}"

            group_stack+=( "${pd_group}" )
            pd_group_created=x
        elif [[ ${token} = '(' ]]; then
            # beginning of a group; usually it is already created,
            # because it is an "any of" or "use" group, but it is
            # legal to specify just a "all of" group
            if [[ -n ${pd_group_created} ]]; then
                pd_group_created=
            else
                group_gen_varname pd_group
                group_declare "${pd_group}"

                item_gen_varname pd_item
                item_declare "${pd_item}"
                local -n i=${pd_item}
                i="g:${pd_group}"
                unset -n i

                group_add_item "${group_stack[-1]}" "${pd_item}"

                group_stack+=( "${pd_group}" )
            fi
        elif [[ ${token} = ')' ]]; then
            # end of a group, pop it from the stack
            last_index=$(( ${#group_stack[@]} - 1 ))
            unset "group_stack[${last_index}]"
        elif [[ ${token} =~ ^[A-Za-z0-9_][A-Za-z0-9+_.-]*$ ]]; then
            # license
            if [[ ${dsf_type} -ne ${DSF_LICENSE} ]]; then
                fail "license tokens are only allowed for LICENSE keys (token: ${token@Q})"
            fi

            item_gen_varname pd_item
            item_declare "${pd_item}"
            local -n i=${pd_item}
            i="l:${token}"
            unset -n i
            group_add_item "${group_stack[-1]}" "${pd_item}"
        elif [[ ${token} =~ ^!?!?(<|<=|=|~|>=|>)?[A-Za-z0-9_][A-Za-z0-9+_.-]*/[A-Za-z0-9_] ]]; then
            # pds
            if [[ ${dsf_type} -ne ${DSF_DEPEND} ]]; then
                fail "package dependency specification is only allowed for DEPEND-like keys (token: ${token@Q})"
            fi

            local blocks=${PDS_NO_BLOCK} operator='' name='' version='' slot=''
            local -a use_requirements=()

            case ${token} in
                '!!'*)
                    blocks=${PDS_STRONG_BLOCK}
                    token=${token:2}
                    ;;
                '!'*)
                    blocks=${PDS_WEAK_BLOCK}
                    token=${token:1}
                    ;;
            esac

            case ${token} in
                '<='*|'>='*)
                    operator=${token:0:2}
                    token=${token:2}
                    ;;
                '<'*|'='*|'~'*|'>'*)
                    operator=${token:0:1}
                    token=${token:1}
                    ;;
            esac

            if [[ ${token} = *']' ]]; then
                local use_reqs_string=${token#*'['}
                use_reqs_string=${use_reqs_string%']'}
                token=${token%"[${use_reqs_string}]"}
                local -a use_reqs
                mapfile -t use_reqs <<<"${use_reqs_string//,/$'\n'}"

                unset use_reqs_string

                local ur name mode pretend pd_ur
                for ur in "${use_reqs[@]}"; do
                    name=''
                    mode=''
                    pretend=''
                    if [[ ${ur} = '!'* ]]; then
                        mode+='!'
                        ur=${ur#'!'}
                    fi
                    case ${ur} in
                        *'=')
                            mode+='='
                            ur=${ur%'='}
                            ;;
                        *'?')
                            mode+='?'
                            ur=${ur%'?'}
                            ;;
                    esac
                    if [[ ${ur} =~ \(([+-])\)$ ]]; then
                        pretend=${BASH_REMATCH[1]}
                        ur=${ur%"(${pretend})"}
                    fi
                    name=${ur}
                    ur_gen_varname pd_ur
                    ur_declare "${pd_ur}"
                    local -n u=${pd_ur}
                    u['n']=${name}
                    u['m']=${mode}
                    u['p']=${pretend}
                    unset -n u
                    use_requirements+=( "${pd_ur}" )
                done
                unset pd_ur pretend mode name ur use_reqs
            fi

            if [[ ${token} = *:* ]]; then
                slot=${token#*:}
                token=${token%:"${slot}"}
            fi

            if [[ ${token} =~ -([0-9]+(\.[0-9]+)*[a-z]?((_alpha|_beta|_pre|_rc|_p)[0-9]*)*(-r[0-9]+)?)$ ]]; then
                version=${BASH_REMATCH[1]}
                token=${token%"-${version}"}
            fi
            name=${token}

            pds_gen_varname pd_pds
            pds_declare "${pd_pds}"
            local -n p=${pd_pds}
            p['b']=${blocks}
            p['o']=${operator}
            p['n']=${name}
            p['v']=${version}
            p['s']=${slot}
            unset -n p
            pds_add_urs "${pd_pds}" "${use_requirements[@]}"
            unset use_requirements slot version name operator blocks

            item_gen_varname pd_item
            item_declare "${pd_item}"
            local -n i=${pd_item}
            i="p:${pd_pds}"
            unset -n i

            group_add_item "${group_stack[-1]}" "${pd_item}"
        else
            fail "unknown token ${token@Q}"
        fi
    done

    if [[ ${#group_stack[@]} -ne 1 ]]; then
        fail "botched parsing, group stack has ${#group_stack[@]} groups instead of 1"
    fi

    # shellcheck disable=SC2034 # it is a reference to an external variable
    top_group_name=${group_stack[0]}
    return 0
}

function parse_eclasses() {
    local eclasses_string=${1}; shift
    local -n eclasses=${1}; shift

    local -a tokens
    mapfile -t tokens <<<"${eclasses_string//$'\t'/$'\n'}"

    local token
    local -i eclass_name_now=1
    for token in "${tokens[@]}"; do
        if [[ ${eclass_name_now} -eq 1 ]]; then
            eclasses+=( "${token}" )
        fi
        eclass_name_now=$((eclass_name_now ^ 1))
    done
    return 0
}

function pds_to_string() {
    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays/maps
    local -n pds=${1}; shift
    local -n str=${1}; shift

    case ${pds['b']} in
        "${PDS_NO_BLOCK}")
            str=''
            ;;
        "${PDS_WEAK_BLOCK}")
            str='!'
            ;;
        "${PDS_STRONG_BLOCK}")
            str='!!'
            ;;
    esac
    str+=${pds['o']}${pds['n']}
    local v=${pds['v']}
    if [[ -n ${v} ]]; then
        str+=-${v}
    fi
    local s=${pds['s']}
    if [[ -n ${s} ]]; then
        str+=:${s}
    fi
    local -n urs=${pds['u']}
    if [[ ${#urs[@]} -gt 0 ]]; then
        str+='['
        local u ur_str
        for u in "${urs[@]}"; do
            ur_to_string "${u}" ur_str
            str+=${ur_str},
        done
        unset ur_str u
        str=${str:0:$(( ${#str} - 1 ))}']'
    fi
}

# use requirement map
#
# n - name of USE flag
# m - mode: +, =, !=, ?, !?, - (+ enabled, = strict relation, != reverted strict relation, ? enabled if enabled, !? disabled if disabled, - disabled)
# p - pretend: empty, + or - (+ pretend enabled if missing, - pretend disabled if missing)

function ur_to_string() {
    local -n ur=${1}; shift
    local -n str=${1}; shift

    case ${ur['m']} in
        '!'*)
            str='!'
            ;;
        '-'*)
            str='-'
            ;;
        *)
            str=''
            ;;
    esac
    str+=${ur['n']}

    # shellcheck disable=SC2178 # shellcheck is confused here
    local p=${ur['p']}
    # shellcheck disable=SC2128 # shellcheck is confused here (p is not an array)
    if [[ -n ${p} ]]; then
        str+="(${p})"
    fi
    case ${ur['m']} in
        *'=')
            str+='='
            ;;
        *'?')
            str+='?'
            ;;
    esac
}

function item_to_string() {
    local -n item=${1}; shift
    local -n str=${1}; shift

    local t=${item:0:1}
    case ${t} in
        e)
            str=''
            ;;
        g)
            local group_name=${item:2}
            local group_str
            group_to_string "${group_name}" group_str
            str=${group_str}
            unset group_str group_name
            ;;
        l)
            str=${item:2}
            ;;
        p)
            local pds_name=${item:2}
            local pds_str=''
            pds_to_string "${pds_name}" pds_str
            str=${pds_str}
            unset pds_str pds_name
            ;;
    esac
}

function group_to_string() {
    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays/maps
    local -n group=${1}; shift
    local -n str=${1}; shift

    local t=${group['t']}
    case ${t} in
        "${GROUP_ALL_OF}")
            local u=${group['u']}
            if [[ -n ${u} ]]; then
                local d=${group['d']}
                case ${d} in
                    "${GROUP_USE_ENABLED}")
                        str=''
                        ;;
                    "${GROUP_USE_DISABLED}")
                        str='!'
                esac
                unset d
                str+="${u}? "
            else
                str=''
            fi
            unset u
            ;;
        "${GROUP_ANY_OF}")
            str='|| '
            ;;
    esac

    str+='( '
    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays/maps
    local -n items=${group['i']}
    if [[ ${#items[@]} -gt 0 ]]; then
        local i item_str
        for i in "${items[@]}"; do
            item_to_string "${i}" item_str
            str+="${item_str} "
        done
        unset item_str i
    fi
    str+=')'
}

function parse_keywords() {
    local keywords_string=${1}; shift
    local -n keywords=${1}; shift
    # rest are architectures

    local -A keywords_set=()

    local -a tokens
    mapfile -t tokens <<<"${keywords_string// /$'\n'}"
    local token
    for token in "${tokens[@]}"; do
        keywords_set["${token}"]=x
    done

    local has_hyphen_star=${keywords_set['-*']:-}
    local arch mark kw
    for arch; do
        for kw in "${arch}" "~${arch}" "-${arch}"; do
            mark=${keywords_set["${kw}"]:-}
            if [[ -n ${mark} ]]; then
                keywords+=( "${kw}" )
                break
            fi
        done
        if [[ -z ${mark} && -n ${has_hyphen_star} ]]; then
            keywords+=( "-${arch}" )
        fi
    done
}


# use requirement map
#
# n - name of IUSE flag
# m - 0 or 1 (0 disabled, 1 enabled)

# shellcheck disable=SC2034 # used indirectly through __mcl_gen_varname
declare -i IUSE_COUNTER=0
declare -ri IUSE_DISABLED=0
declare -ri IUSE_ENABLED=1

function iuse_gen_varname() {
    __mcl_gen_varname "${1}" IUSE
}

function iuse_declare() {
    __mcl_declare -g -A "${@}" "( [n]=ITS_UNSET [m]=${IUSE_DISABLED} )"
}

function iuse_unset() {
    unset "${1}"
}

function parse_iuse() {
    local iuse_string=${1}; shift
    local -n iuse=${1}; shift

    local -a tokens
    mapfile -t tokens <<<"${iuse_string// /$'\n'}"
    local token pi_iuse
    for token in "${tokens[@]}"; do
        iuse_gen_varname pi_iuse
        iuse_declare "${pi_iuse}"
        local -n i=${pi_iuse}
        if [[ ${token} = '+'* ]]; then
            i['m']=${IUSE_ENABLED}
            token=${token:1}
        fi
        i['n']=${token}
        unset -n i
        iuse+=( "${pi_iuse}" )
    done
}

function iuse_to_string() {
    # shellcheck disable=SC2178 # shellcheck doesn't grok references to arrays/maps
    local -n iuse=${1}; shift
    local -n str=${1}; shift

    case ${iuse['m']} in
        "${IUSE_ENABLED}")
            str='+'
            ;;
        "${IUSE_DISABLED}")
            str=''
            ;;
    esac
    use_str+=${iuse['n']}
}

fi
