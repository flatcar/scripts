#!/bin/bash

if [[ -z ${__JOBS_LIB_SH_INCLUDED__:-} ]]; then
__JOBS_LIB_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

declare -gri JOB_INFD_IDX=0 JOB_OUTFD_IDX=1 JOB_ERRFD_IDX=2 JOB_PID_IDX=3
function job_declare() {
    struct_declare -ga "${@}" "('-1' '-1' '-1' '-1')"
}

function job_unset() {
    unset "${@}"
}

function job_run() {
    local merge_out_with_err=
    if [[ ${1:-} = '-m' ]]; then
        shift
        merge_out_with_err=x
    fi
    local -n job_ref=${1}; shift
    # rest are function and args to run

    local -i pid=${job_ref[JOB_PID_IDX]} infd=${job_ref[JOB_INFD_IDX]} outfd=${job_ref[JOB_OUTFD_IDX]} errfd=${job_ref[JOB_ERRFD_IDX]}
    if [[ pid -ne -1 || infd -ne -1 || outfd -ne -1 || errfd -ne -1 ]]; then
        fail "trying to run a job (${*@Q}), while one is already running (pid: ${pid})"
    fi

    local fd_var_name path
    local -i new_fd
    local -a var_names=( infd outfd )
    if [[ -z ${merge_out_with_err} ]]; then
        var_names+=( errfd )
    fi
    for fd_var_name in "${var_names[@]}"; do
        local -n fifo_fd_ref=${fd_var_name}
        path=$(mktemp -t -u pipe-XXXXXXXXXXXXXXXXX)

        mkfifo "${path}"
        exec {new_fd}<>"${path}"
        rm -f "${path}"
        fifo_fd_ref=${new_fd}
        unset -n fifo_fd_ref
    done
    if [[ -n ${merge_out_with_err} ]]; then
        errfd=${outfd}
    fi
    __jl_job_runner__ "${@}" <&${infd} >&${outfd} 2>&${errfd} &
    pid=${!}
    job_ref[JOB_PID_IDX]=${pid}
    job_ref[JOB_INFD_IDX]=${infd}
    job_ref[JOB_OUTFD_IDX]=${outfd}
    job_ref[JOB_ERRFD_IDX]=${errfd}
}

function job_reap() {
    local -n job_ref=${1}; shift
    local -n exit_status_ref=${1}; shift

    local -i pid=${job_ref[JOB_PID_IDX]} infd=${job_ref[JOB_INFD_IDX]} outfd=${job_ref[JOB_OUTFD_IDX]} errfd=${job_ref[JOB_ERRFD_IDX]}
    if [[ pid -eq -1 || infd -eq -1 || outfd -eq -1 || errfd -eq -1 ]]; then
        fail "trying to reap nonexistent job"
    fi

    local -i es=0
    wait "${pid}" || es=${?}

    local fd_var_name
    local -i old_fd
    local -a var_names=(infd outfd)
    if [[ outfd -ne errfd ]]; then
        var_names+=( errfd )
    fi
    for fd_var_name in "${var_names[@]}"; do
        local -n fifo_fd_ref=${fd_var_name}
        old_fd=${fifo_fd_ref}
        exec {old_fd}>&-
        unset -n fifo_fd_ref
    done
    job_ref[JOB_PID_IDX]=-1
    job_ref[JOB_INFD_IDX]=-1
    job_ref[JOB_OUTFD_IDX]=-1
    job_ref[JOB_ERRFD_IDX]=-1
    exit_status_ref=${es}
}

function job_is_alive() {
    local -n job_ref=${1}; shift

    local -i pid=${job_ref[JOB_PID_IDX]}
    if [[ pid -eq -1 ]]; then
        fail "checking status of not-yet-running or already-reaped job"
    fi
    # dc - don't care
    local status dc
    local -i ppid
    {
        read -r dc dc status ppid dc <"/proc/${pid}/stat" || return 1
    } >/dev/null 2>&1
    if [[ ppid -ne ${BASHPID} && ppid -ne ${$} ]]; then
        # parent pid mismatch, this means that our child died and the
        # pid got reused
        return 1
    fi
    case ${status} in
        x|X|Z)
            # I don't think I have ever reached this line.
            return 1
            ;;
    esac
    return 0
}

function job_send_input() {
    local -n job_ref=${1}; shift
    # rest are lines to send
    local -i infd=${job_ref[JOB_INFD_IDX]}

    printf '%s\n' "${@}" >&${infd}
}

function job_get_output() {
    local -n job_ref=${1}; shift
    local -n output_lines_ref=${1}; shift

    local -i outfd=${job_ref[JOB_OUTFD_IDX]} errfd=${job_ref[JOB_ERRFD_IDX]}
    local REPLY got_output=x

    output_lines_ref=()
    while [[ -n ${got_output} ]]; do
        got_output=
        if read -t 0 -u ${outfd}; then
            read -r -u ${outfd}
            output_lines_ref+=( "${REPLY}" )
            got_output=x
        fi
        if [[ errfd -ne outfd ]] && read -t 0 -u ${errfd}; then
            read -r -u ${errfd}
            output_lines_ref+=( "${REPLY}" )
            got_output=x
        fi
    done
}

function __jl_job_runner__() {
    set -euo pipefail
    "${@}"
}

fi
