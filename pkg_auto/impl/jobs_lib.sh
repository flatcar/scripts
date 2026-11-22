#!/bin/bash

# This file implements a simple jobs functionality - running tasks in
# separate processes. Communication with the job goes through standard
# input/output/error.
#
# An example use of the library is as follows:
#
# # Echoes everything received on standard input to standard
# # output. Will finish if receives "shutdown".
# function echoer_job() {
#     local REPLY
#     while read -r; do
#         echo "${REPLY}"
#         if [[ ${REPLY} = 'shutdown' ]]; then
#             return 0
#         fi
#     done
# }
#
# job_declare echoer
# job_run -m echoer_job
# job_send_input echoer one two three shutdown
# declare -a echoer_lines=()
# declare echoer_done=''
# while [[ -z ${echoer_done} ]]; do
#     if ! job_is_alive echoer; then
#         echoer_done=x
#     fi
#     job_get_output echoer echoer_lines
#     printf '%s\n' ${echoer_lines[@]/#/'from echoer job: '}
#     sleep 0.1
# done
# declare -i echoer_exit_status
# job_reap echoer echoer_exit_status
# job_unset echoer
# echo "echoer done with exit status ${exit_status}"


if [[ -z ${__JOBS_LIB_SH_INCLUDED__:-} ]]; then
__JOBS_LIB_SH_INCLUDED__=x

source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# Fields of the job struct.
#
# JOB_INFD_IDX - descriptor for standard input
#
# JOB_OUTFD_IDX - descriptor for standard output
#
# JOB_ERRFD_IDX - descriptor for standard error
#
# JOB_PID_IDX - job PID
declare -gri JOB_INFD_IDX=0 JOB_OUTFD_IDX=1 JOB_ERRFD_IDX=2 JOB_PID_IDX=3

# Declare job variables.
#
# Parameters:
#
# @ - names of variables to be used for jobs
function job_declare() {
    struct_declare -ga "${@}" "('-1' '-1' '-1' '-1')"
}

# Unset job variables.
#
# Parameters:
#
# @ - names of job variables
function job_unset() {
    unset "${@}"
}

# Kick off the job. The passed function will be run as a separate
# process, and following parameters will be passed to the
# function. For this to work, the job must be just-declared or reaped.
#
# Flags:
#
# -m - merge standard output and standard error into one descriptor
#
# Parameters:
#
# 1 - job
# @ - function to run, followed by its parameters
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

# Reap the dead job and get its exit status. After this call, the job
# can be reused for another run or unset.
#
# Parameters:
#
# 1 - job
# 2 - name of a scalar variable, where exit status will be stored
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

# Check if job is still alive. Returns true if so, otherwise false.
#
# Parameters:
#
# 1 - job
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

# Send data to the job. Every data parameter will be a separate line.
#
# Parameters:
#
# 1 - job
# @ - data to send
function job_send_input() {
    local -n job_ref=${1}; shift
    # rest are lines to send
    local -i infd=${job_ref[JOB_INFD_IDX]}

    printf '%s\n' "${@}" >&${infd}
}

# Get output from the job. Tries to read a line from standard output,
# then a line from standard error. If any of the reads returned data,
# it will repeat the operations. If -m was passed to job_run, then it
# will only read from standard output.
#
# Parameters:
#
# 1 - job
# 2 - name of an array variable where the read lines will be stored
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
