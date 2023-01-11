#!/bin/bash

set -euo pipefail

msg() {
    printf 'test-kola.sh: %s\n' "$*"
}

fail() {
    msg "$*" >&2
    exit 1
}

if [[ ${#} -eq 0 ]]; then
    fail "needs to be run with either 'run' or 'list' command"
fi

all_tests=(
    'fail.setup'
    'fail.kola'
    'fail.timeout'
    'cl.internet'
    'cl.basic'
)

new_args=()
for arg; do
    if [[ "${arg}" = --*=* ]]; then
        value="${arg#*=}"
        arg="${arg%%=*}"
        new_args+=( "${arg}" "${value}" )
    else
        new_args+=( "${arg}" )
    fi
done

set -- "${new_args[@]}"

case "${1}" in
    list)
        shift
        platform=''
        filter=0
        while [[ "${#}" -gt 0 ]]; do
            case "${1}" in
                --platform)
                    platform="${2}"
                    shift 2
                    ;;
                --filter)
                    filter=1
                    shift
                    ;;
                --*)
                    fail "unknown flag '${1}' for list"
                    ;;
                *)
                    break
                    ;;
            esac
        done
        if [[ "${platform}" != 'test' ]]; then
            fail "wrong platform '${platform}', should be 'test'"
        fi
        if [[ "${filter}" -eq 0 ]]; then
            fail 'missing --filter flag'
        fi
        print_all=0
        if [[ "${#}" -eq 0 ]]; then
            print_all=1
        elif [[ "${#}" -eq 1 ]] && [[ "${1}" = '*' ]]; then
            print_all=1
        fi
        printf 'headers line\nempty line\n'
        if [[ ${print_all} -eq 1 ]]; then
            printf '%s\n' "${all_tests[@]}"
        else
            for test_name; do
                for known_test_name in "${all_tests[@]}"; do
                    if [[ "${test_name}" = "${known_test_name}" ]]; then
                        printf '%s\n' "${test_name}"
                    fi
                done
            done
        fi
        exit 0
        ;;
    run)
        shift
        board=''
        channel=''
        tapfile=''
        torcx_manifest=''
        platform=''
        parallel='0'
        fail=-0
        while [[ "${#}" -gt 0 ]]; do
            case "${1}" in
                --board)
                    board="${2}"
                    shift 2
                    ;;
                --channel)
                    channel="${2}"
                    shift 2
                    ;;
                --platform)
                    platform="${2}"
                    shift 2
                    ;;
                --tapfile)
                    tapfile="${2}"
                    shift 2
                    ;;
                --torcx-manifest)
                    torcx_manifest="${2}"
                    shift 2
                    ;;
                --parallel)
                    parallel="${2}"
                    shift 2
                    ;;
                *)
                    break
                    ;;
            esac
        done
        if [[ -z "${board}" ]]; then
            fail 'no --board passed'
        fi
        if [[ -z "${channel}" ]]; then
            fail 'no --channel passed'
        fi
        if [[ -z "${tapfile}" ]]; then
            fail 'no --tapfile passed'
        fi
        if [[ -z "${torcx_manifest}" ]]; then
            fail 'no --torcx-manifest passed'
        fi
        # doing string comparisons, because parallel and platform can be anything
        if [[ "${parallel}" != "42" ]]; then
            fail "expected --parallel with 42, got '${parallel}'"
        fi
        if [[ "${platform}" != "test" ]]; then
            fail "expected --platform with 'test', got '${platform}'"
        fi

        for test_name; do
            case "${test_name}" in
                'fail.kola')
                    fail=1
                    break
                    ;;
                'fail.timeout')
                    sleep 20s
                    break
                    ;;
            esac
        done
        result='ok'
        if [[ ${fail} -eq 1 ]]; then
            result='not ok'
        fi
        wildcard=0
        if [[ ${#} -eq 0 ]]; then
            wildcard=1
        elif [[ ${#} -eq 1 ]] && [[ "${1}" = '*' ]]; then
            wildcard=1
        fi
        if [[ ${wildcard} -eq 1 ]]; then
            set -- "${all_tests[@]}"
        fi
        printf '1..%s\n' ${#} >"${tapfile}"
        format="${result}"' - %s\n'
        printf "${format}" "${@}" >>"${tapfile}"
        exit ${fail}
        ;;
    *)
        fail "unknown command '${1}'"
        ;;
esac
