#!/bin/bash
#
# Copyright (c) 2021 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Helper script for extracting information from TAP files and for merging multiple
#  TAP files into one report.
# The script uses a temporary SQLite DB for querying and for result generation.
#
# Brief usage overview (scroll down for parameters etc.):
#   tap_ingest_tapfile - add test results from tap file to the DB 
#   tap_list_vendors   - list all vendors TAP files have been ingested for
#   tap_failed_tests_for_vendor - list all tests that never succeded even once, per vendor
#   tap_generate_report - generate a merged test report


TAPFILE_HELPER_DBNAME="results.sqlite3"

# wrapper around sqlite3 w/ retries if DB is locked
function __sqlite3_wrapper() {
    local dbfile="${TAPFILE_HELPER_DBNAME}"

    local params=""
    while [[ "$1" == -* ]] ; do
        params="$params $1"
        shift
    done

    while true; do
        sqlite3 "${dbfile}" $params "PRAGMA foreign_keys = ON;$@"
        local ret="$?"
        if [ "$ret" -ne 5 ] ; then
            return $ret
        fi
        local sleep="$((1 + $RANDOM % 5))"
        echo "Retrying in ${sleep} seconds." >&2
        sleep "${sleep}"
    done
}
# --

# Initialise the DB if it wasn't yet.
function __db_init() {

    __sqlite3_wrapper '
    CREATE TABLE IF NOT EXISTS "test_case" (
        "id"    INTEGER,
        "name"  TEXT UNIQUE,
        PRIMARY KEY("id")
    );
    CREATE TABLE IF NOT EXISTS "vendor" (
        "id"    INTEGER,
        "name"  TEXT UNIQUE,
        PRIMARY KEY("id")
    );
    CREATE TABLE IF NOT EXISTS "test_run" (
        "id"        INTEGER NOT NULL,
        "result"    INTEGER NOT NULL,
        "output"    TEXT,
        "case_id"   INTEGER NOT NULL,
        "run"       INTEGER NOT NULL,
        "vendor_id" INTEGER,
        PRIMARY KEY("id"),
        FOREIGN KEY("case_id") REFERENCES "test_case"("id"),
        FOREIGN KEY("vendor_id") REFERENCES "vendor"("id"),
        UNIQUE (case_id, run, vendor_id)
    );
'
}
# --

# Read tapfile into temporary DB.
# INPUT:
# 1: <tapfile> - tapfile to ingest
# 2: <vendor>  - vendor (qemu, azure, aws, etc...)
# 3: <run>     - re-run iteration

function tap_ingest_tapfile() {

    local tapfile="${1}"
    local vendor="${2}"
    local run="${3}"

    local result=""
    local test_name=""
    local in_error_message=false

    if ! [ -f "${TAPFILE_HELPER_DBNAME}" ] ; then
       __db_init
    fi

    # Wrap all SQL commands in a transaction to speed up INSERTs
    # We will commit intermediately if there's an error message to insert so the
    # error message file can be reused.
    local SQL="BEGIN TRANSACTION;"
    local has_error_message="false"


    # run the parse loop in a subshell and clean up temporary error message file on exit
    (
        local error_message_file="$(mktemp)"
        trap "rm -f '${error_message_file}'" EXIT
        # Example TAP input:
        # ok - coreos.auth.verify
        # ok - coreos.locksmith.tls
        # not ok - cl.filesystem
        #   ---
        #   Error: "--- FAIL: cl.filesystem/deadlinks (1.86s)\n            files.go:90: Dead symbolic links found: [/var/lib/flatcar-oem-gce/usr/lib64/python3.9/site-packages/certifi-3021.3.16-py3.9.egg-info]"
        #   ...
        # ok - cl.cloudinit.script
        # ok - kubeadm.v1.22.0.flannel.base
        while read -r line; do
            if [[ "${line}" == "1.."* ]] ; then continue; fi
            if [ "${line}" = "---" ] ; then  # note: read removes leading whitespaces
                in_error_message=true
                continue
            fi

            if $in_error_message ; then
                if [ "${line}" = "..." ] ; then
                    in_error_message=false
                    has_error_message="true"
                else
                    # remove special characters and unicode. Jenkins TAP parser don't unicode.
                    echo -e "$line" \
                        | LC_ALL=C sed -e 's/^Error: "--- FAIL: /"/' -e 's/^[[:space:]]*//' \
                              -e "s/[>\\\"']/_/g" -e 's/[[:space:]]/ /g' \
                              -e 's/.\{200\}/&\n/g' \
                              -e 's/[^\x1F-\x7F]/?/g' \
                        >> "${error_message_file}"
                    continue
                fi
            else
                test_name="$(echo "${line}" | sed 's/^[^-]* - //')"
                local result_string
                result_string="$(echo "${line}" | sed 's/ - .*//')"
                result=0
                if [ "${result_string}" = "ok" ] ; then
                    result=1
                fi
            fi

            local test_output="/dev/null"
            if [ "${has_error_message}" = "true" ] ; then
                test_output="${error_message_file}"
            fi
            SQL="${SQL}INSERT OR IGNORE INTO test_case(name) VALUES ('${test_name}');"
            SQL="${SQL}INSERT OR IGNORE INTO vendor(name) VALUES ('${vendor}');"

            SQL="${SQL}INSERT OR REPLACE INTO test_run(run,result,output,case_id,vendor_id)
                                 VALUES ('${run}','${result}', readfile('${test_output}'),
                                         (SELECT id FROM test_case WHERE name='${test_name}'),
                                         (SELECT id FROM vendor WHERE name='${vendor}'));"

            if [ "${has_error_message}" = "true" ] ; then
                SQL="${SQL}COMMIT;"
                __sqlite3_wrapper "${SQL}"
                truncate --size 0 "${error_message_file}"
                has_error_message="false"
                SQL="BEGIN TRANSACTION;"
            fi

        done < "$tapfile"
        SQL="${SQL}COMMIT;"
        __sqlite3_wrapper "${SQL}"
    )
}
# --

# Print a list of all vendors we've seen so far.
function tap_list_vendors() {
    __sqlite3_wrapper 'SELECT DISTINCT name from vendor;'
}
# --

# List tests that never succeeded for a given vendor.
# INPUT:
# 1: <vendor> - Vendor name to check for failed test runs
function tap_failed_tests_for_vendor() {
    local vendor="$1"

    __sqlite3_wrapper "
		SELECT failed.name FROM test_case AS failed
		WHERE EXISTS (
				SELECT * FROM test_run AS t, vendor AS v, test_case AS c
				WHERE t.vendor_id=v.id AND t.case_id=c.id               
					AND v.name='${vendor}'
					AND c.name=failed.name
			)
			AND NOT exists (
				SELECT * FROM test_run AS t, vendor AS v, test_case AS c
				WHERE t.vendor_id=v.id AND t.case_id=c.id               
					AND v.name='${vendor}'
					AND c.name=failed.name
					AND t.result=1 );"
}
# --

# TAP output format primitives for tap_generate_report()

__tap_print_header() {
    local arch="$1"
    local version="$2"
    local vendors="$3"
    local count="$4"

    # We use count + 1 here because the very first "test result" will just print
    #  the list of platforms tested, not an actual test's result.
    echo "1..$((count+1))"
    echo "ok - Version: ${version}, Architecture: ${arch}"
    echo "   ---"
    echo "   Platforms tested: ${vendors}"
    echo "   ..."
}
# --

__tap_print_test_verdict() {
    local verdict="$1"
    local name="$2"
    local succeded_vendors="$3"
    local failed_vendors="$4"

    echo "${verdict} - ${test_name}"
    echo "   ---"

    if [ -n "${succeded_vendors}" ] ; then
        echo "   Succeeded: ${succeded_vendors}"
    fi
    if [ -n "${failed_vendors}" ] ; then
        echo "   Failed: ${failed_vendors}"
    fi
}
# --

__tap_print_test_run_diag_output() {
    local vendor="$1"
    local run="$2"
    echo "   Error messages for ${vendor}, run ${run}:"
    cat -
}
# --

__tap_finish_test_verdict() {
    local verdict="$1"
    local name="$2"
    local succeded_vendors="$3"
    local failed_vendors="$4"
    echo "   ..."
}
# --

__tap_finish_test_report() {
    true
}
# --

# markdown output format primitives for tap_generate_report()

__md_print_header() {
    local arch="$1"
    local version="$2"
    local vendors="$3"
    local count="$4"

    echo "### Test report for ${version} / ${arch}"
    echo
    echo "**Platforms tested** : ${vendors}"
}
# --

__md_print_test_verdict() {
    local verdict="$1"
    local name="$2"
    local succeded_vendors="$3"
    local failed_vendors="$4"

    v="![${verdict}](https://via.placeholder.com/50x20/00ff00/000000?text=PASS)"
    if [ "${verdict}" = "not ok" ] ; then
        v="![${verdict}](https://via.placeholder.com/50x20/ff0000/ffffff?text=FAIL)"
    fi

    echo
    echo -n "${v} **${name}**"
    if [ -n "${succeded_vendors}" ] ; then
        echo -n " 🟢 Succeeded: ${succeded_vendors}"
    fi
    if [ -n "${failed_vendors}" ] ; then
        echo -n " ❌ Failed: ${failed_vendors}"
    fi
    echo
    if [ "${verdict}" = "not ok" ] ; then
        echo
        echo "<details>"
        echo
    fi
}
# --

__md_print_test_run_diag_output() {
    local vendor="$1"
    local run="$2"

    echo "* Diagnostic output for ${vendor}, run ${run}"
    echo
    echo "  \`\`\`"
    cat -
    echo "  \`\`\`"
    echo

}
# --
#
__md_finish_test_verdict() {
    local verdict="$1"
    local name="$2"
    local succeded_vendors="$3"
    local failed_vendors="$4"
    if [ "${verdict}" = "not ok" ] ; then
        echo
        echo "</details>"
        echo
    fi
}
# --

__md_finish_test_report() {
    true
}
# --


# Print the tap file from contents of the database.
# INPUT:
# 1: <arch>    - Architecture to be included in the first line of the report
# 2: <version> - OS version tested, to be included in the first line of the report
# 3: <format>  - Output format of the report. "tap" and "markdown" are supported.
# 4: <include_transient_errors> - If set to "true" then debug output of transient test failures
#                   is included in the result report.
function tap_generate_report() {
    local arch="$1"
    local version="$2"
    local format="$3"
    local full_error_report="${4:-false}"

    case "${format}" in
        tap) ;;
        md) ;;
        *) echo "ERROR: tap_generate_report() unknown format '${format}'" >&2
           return 1
           ;;
    esac


    local count
    count="$(__sqlite3_wrapper 'SELECT count(name) FROM test_case;')"
    local vendors
    vendors="$(__sqlite3_wrapper 'SELECT name FROM vendor;' | tr '\n' ' ')"

    __"${format}"_print_header "${arch}" "${version}" "${vendors}" "${count}"

    # Print result line for every test, including platforms it succeeded on
    #  and transient failed runs.
    __sqlite3_wrapper 'SELECT DISTINCT name from test_case;' | \
    while read -r test_name; do

        # "ok" if the test succeeded at least once for all vendors that run the test,
        #   "not ok" otherwise.
        local verdict
        verdict="$(__sqlite3_wrapper "
        SELECT failed.name FROM vendor AS failed
        WHERE EXISTS (
                SELECT * FROM test_run AS t, vendor AS v, test_case AS c
                WHERE t.vendor_id=v.id AND t.case_id=c.id
                    AND v.name=failed.name
                    AND c.name='${test_name}'
            )
            AND NOT exists (
                SELECT * FROM test_run AS t, vendor AS v, test_case AS c
                WHERE t.vendor_id=v.id AND t.case_id=c.id
                    AND v.name=failed.name
                    AND c.name='${test_name}'
                    AND t.result=1 );
        ")"
        if [ -n "${verdict}" ] ; then
            verdict="not ok"
        else
            verdict="ok"
        fi

        # Generate a list of vendors and respective runs, in a single line.
        function list_runs() {
            local res="$1"
            __sqlite3_wrapper -csv "
                SELECT v.name, t.run FROM test_run AS t, vendor AS v, test_case AS c
                WHERE t.vendor_id=v.id AND t.case_id=c.id
                    AND c.name='${test_name}'
                    AND t.result=${res}
                    ORDER BY v.name;" \
                | awk -F, '{ if (t && (t != $1)) {
                                printf t " " r "); "
                                r="";}
                             t=$1
                             if (r)
                                r=r ", " $2
                             else
                                r="(" $2 ; }
                            END { if (t) print t " " r ")"; }'
        }

        local succeeded
        succeeded="$(list_runs 1)"
        local failed
        failed="$(list_runs 0)"

        __"${format}"_print_test_verdict "${verdict}" "${test_name}" \
                                        "${succeeded}" "${failed}"
        if [ -n "${failed}" ] ; then
            if [ "${verdict}" = "not ok" -o "${full_error_report}" = "true" ] ; then
                # generate diagnostic output, per failed run.
                __sqlite3_wrapper -csv "
                SELECT v.name, t.run
                    FROM test_run AS t, vendor AS v, test_case AS c
                    WHERE t.vendor_id=v.id AND t.case_id=c.id
                    AND c.name='${test_name}'
                    AND t.result=0
                    ORDER BY t.run DESC;" | \
                sed 's/,/ /' | \
                while read -r vendor run; do
                {
                    __sqlite3_wrapper -csv "
                    SELECT t.output FROM test_run AS t, test_case AS c
                        WHERE t.case_id=c.id
                        AND c.name='${test_name}'
                        AND t.run='${run}';" | \
                    sed 's/"/ /g' | \
                    awk '{print "      L" NR ": \"" $0 "\""}'
                } | __"${format}"_print_test_run_diag_output "${vendor}" "${run}"
                done
            fi
        fi
        __"${format}"_finish_test_verdict "${verdict}" "${test_name}" \
                                        "${succeeded}" "${failed}"
    done

    __"${format}"_finish_test_report
}
# --
