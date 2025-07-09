#!/bin/bash

set -euo pipefail

declare -ga BUILD_TYPES=(
    sdk
    packages
)

declare -ga TESTCASES=(
    not_a_nightly # tag pushed
    nightly_not_HEAD # fail
    nightly_HEAD_no_tags # tag pushed, commit in branch
    nightly_HEAD_no_nightly_tag # tag pushed, commit in branch
    nightly_HEAD_nightly_tag_with_diff # fail
    nightly_HEAD_nightly_tag_images_exist # nothing to do
    nightly_HEAD_nightly_tag_images_not_exist # tag pushed, commit in branch
)

declare -ga CHECKOUT_TYPES=(
    sane # basically a branch checkout
    fetch_head # git fetch origin ${branch}; git checkout FETCH_HEAD
)

function fail() {
    printf '%s\n' "${*}" >&2
    exit 1
}

declare -g LOGDIR=logs
declare -g START_AT_TC=${TESTCASES[0]} START_AT_BT=${BUILD_TYPES[0]} START_AT_CT=${CHECKOUT_TYPES[0]}

RANDOM=${SRANDOM}${SRANDOM}

while [[ ${#} -gt 0 ]]; do
    case ${1} in
        -l|--log-dir)
            LOGDIR=${2}
            shift 2
            ;;
        -st|--start-at-test)
            tc_ok=''
            for tc in "${TESTCASES[@]}"; do
                if [[ ${tc} = "${2}" ]]; then
                    START_AT_TC=${2}
                    tc_ok=x
                    break
                fi
            done
            if [[ -z ${tc_ok} ]]; then
                fail "wrong testcase name to start at, possible testcase names are ${TESTCASES[*]}"
            fi
            unset tc_ok tc
            shift 2
            ;;
        -sb|--start-at-build)
            bt_ok=''
            for bt in "${BUILD_TYPES[@]}"; do
                if [[ ${bt} = "${2}" ]]; then
                    START_AT_BT=${2}
                    bt_ok=x
                    break
                fi
            done
            if [[ -z ${bt_ok} ]]; then
                fail "wrong build type to start at, possible build types are ${BUILD_TYPES[*]}"
            fi
            unset bt_ok bt
            shift 2
            ;;
        -sc|--start-at-checkout)
            ct_ok=''
            for ct in "${CHECKOUT_TYPES[@]}"; do
                if [[ ${ct} = "${2}" ]]; then
                    START_AT_CT=${2}
                    ct_ok=x
                    break
                fi
            done
            if [[ -z ${ct_ok} ]]; then
                fail "wrong checkout type to start at, possible checkout types are ${CHECKOUT_TYPES[*]}"
            fi
            unset ct_ok ct
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            fail "unknown flag ${1@Q}"
            ;;
    esac
done

declare -g DOT_GIT_PARENT_DIR=

function find_git() {
    local -n git_parent_dir_ref=${1}; shift
    local dir=.

    while [[ $(realpath "${dir}") != '/' ]]; do
        if [[ -e ${dir}/.git ]]; then
            git_parent_dir_ref=${dir}
            return
        fi
        dir+=/..
    done
    fail "need to be running within a git repo"
}
find_git DOT_GIT_PARENT_DIR
unset -f find_git

function log_test() {
    printf '    %s\n' "${*}" >&3
}

function fail_test() {
    log_test "FAIL: ${*}"
    exit 1
}

function vc() { # verbose command
    printf '%s\n' "${*}"
    "${@}"
}

function setup_cleanup_trap() {
    declare -g cleanups_to_execute=':'
    trap "${cleanups_to_execute}" EXIT
}

function add_cleanup() {
    cleanups_to_execute="${1} ; ${cleanups_to_execute}"
    trap "set +e ; log_test 'doing cleanups'; if [[ \${DID_PUSHD} ]]; then popd; fi; ${cleanups_to_execute}" EXIT
}

# avoid zeros - leading zeros are messing things up into octals and
# stuff, meh
declare -ga DIGITS=( {1..9} )
declare -ga ALNUMS=( {1..9} {a..z} {A..Z} )

function random_from_array() {
    local -i count=${1}; shift
    local -n array_ref=${1}; shift
    local -n str_ref=${1}; shift

    local -i i len=${#array_ref[@]}
    local str=''
    for ((i=0; i < count; ++i)); do
        str+=${array_ref[$(( RANDOM % len ))]}
    done

    str_ref=${str}
}

function random_digits() {
    random_from_array "${1}" DIGITS "${2}"
}

function random_alnums() {
    random_from_array "${1}" ALNUMS "${2}"
}

declare -g DID_PUSHD=''

function git_wt_setup_open() {
    local build_type=${1}; shift
    local tag_type=${1}; shift
    local images_exist=${1}; shift
    local -n branch_ref=${1}; shift
    local -n test_script_ref=${1}; shift
    local -n tag_ref=${1}; shift

    local work_dir random_work_dir_part
    random_alnums 8 random_work_dir_part
    local test_name=${FUNCNAME[1]}
    work_dir=${DOT_GIT_PARENT_DIR}/../${test_name}_${build_type}_${random_work_dir_part}

    local random_branch_part random_version_part
    random_alnums 8 random_branch_part
    random_digits 4 random_version_part

    local branch channel version source_file
    local -a function_call export_lines
    case ${build_type} in
        sdk)
            branch=testmaintest${random_branch_part}
            channel=main
            version=${random_version_part}.0.0
            source_file='./ci-automation/sdk_bootstrap.sh'
            # first argument is a seed version, not important at all
            # for testing
            function_call=( 'sdk_bootstrap' '1234.0.0' )
            export_lines=( "CIA_DEBUGMAINBRANCH=${branch}" )
            ;;
        packages)
            branch=testflatcartest${random_branch_part}-${random_version_part}
            channel=stable
            version=${random_version_part}.2.0
            source_file='./ci-automation/packages-tag.sh'
            function_call=( 'packages_tag' )
            export_lines=( "CIA_DEBUGFLATCARBRANCHPREFIX=testflatcartest${random_branch_part}" )
            ;;
        *) fail_test "wrong build type ${build_type@Q}, expected sdk or packages";;
    esac

    local tag random_tag_part
    case ${tag_type} in
        nightly)
            tag=${channel}-${version}-testnightlytest
            random_digits 8 random_tag_part
            tag+="-${random_tag_part}"
            random_digits 4 random_tag_part
            tag+="-${random_tag_part}"
            ;;
        devel)
            random_alnums 8 random_tag_part
            tag=${channel}-${version}-some-devel-stuff-${random_tag_part}
            ;;
        *) fail_test "wrong tag type ${tag_type@Q}, expected nightly or devel";;
    esac
    log_test "will use tag ${tag}"

    log_test "adding worktree at ${work_dir} with branch ${branch}"
    git worktree add -b "${branch}" "${work_dir}"
    add_cleanup "log_test 'removing local branch '${branch@Q}; git branch -D ${branch@Q}"
    add_cleanup "log_test 'removing worktree at '${work_dir@Q}; git worktree remove --force ${work_dir@Q}"

    local test_script=$(mktemp --tmpdir ts-XXXXXXXX.sh)
    log_test "creating test script at ${test_script}"
    add_cleanup "log_test 'removing test script '${test_script@Q}; rm -f ${test_script@Q}"
    printf '%s\n' \
           '#!/bin/bash' \
           'set -euo pipefail' \
           "${export_lines[@]/#/export }" \
           'export CIA_DEBUGNIGHTLY="testnightlytest"' \
           "export CIA_DEBUGIMAGESEXIST=${images_exist@Q}" \
           'export CIA_DEBUGTESTRUN=x' \
           "source ${source_file@Q}" \
           "${function_call[*]@Q}"' "${@}"' >"${test_script}"
    chmod a+x "${test_script}"
    pushd "${work_dir}"
    DID_PUSHD=x

    branch_ref=${branch}
    test_script_ref=${test_script}
    tag_ref=${tag}
}

function git_wt_setup_close_and_run() {
    local branch=${1}; shift
    local test_script=${1}; shift
    local tag=${1}; shift
    local checkout_type=${1}; shift
    local -n ret_ref=${1}; shift
    local -n tag_hash_ref=${1}; shift
    local -n branch_hash_ref=${1}; shift

    case ${checkout_type} in
        sane) :;;
        fetch_head)
            git fetch origin "${branch}"
            git checkout FETCH_HEAD
            ;;
        *) fail_test "wrong checkout type (${checkout_type@Q}), expected sane or fetch_head"
    esac

    log_test "running the test script"
    local -i ret=0
    "${test_script}" "${tag}" || ret=${?}
    add_cleanup "if [[ -n \$(git tag -l ${tag@Q}) ]]; then log_test 'removing local tag '${tag@Q}; git tag -d ${tag@Q}; else log_test 'no local tag '${tag@Q}' to remove'; fi"
    add_cleanup "if [[ -n \$(git ls-remote origin ${tag@Q}) ]]; then log_test 'removing remote tag '${tag@Q}; git push --delete origin ${tag@Q}; else log_test 'no remote tag '${tag@Q}' to remove'; fi"
    popd
    DID_PUSHD=''

    local hash ref tag_hash='' branch_hash=''
    while read hash ref; do
        case ${ref} in
            "refs/tags/${tag}")
                tag_hash=${hash}
                ;;
            "refs/heads/${branch}")
                branch_hash=${hash}
                ;;
        esac
    done < <(git ls-remote origin)

    ret_ref=${ret}
    tag_hash_ref=${tag_hash}
    branch_hash_ref=${branch_hash}
}

function not_a_nightly() (
    local build_type=${1}; shift
    local checkout_type=${1}; shift

    setup_cleanup_trap

    local tc_branch tc_script tc_tag

    git_wt_setup_open "${build_type}" 'devel' 'fail-if-reached' tc_branch tc_script tc_tag

    local tmpfile=$(mktemp testfile-XXXXXXXX)
    log_test "creating a commit and pushing it to remote"
    echo 'foo' >"${tmpfile}"
    git add "${tmpfile}"
    git commit -m 'stuff'
    git push --set-upstream origin "${tc_branch}"
    add_cleanup "log_test 'removing remote branch '${tc_branch@Q}; git push --delete origin ${tc_branch@Q}"

    local -i tc_ret=0
    local tc_tag_hash tc_branch_hash
    git_wt_setup_close_and_run "${tc_branch}" "${tc_script}" "${tc_tag}" "${checkout_type}" tc_ret tc_tag_hash tc_branch_hash

    if [[ tc_ret -ne 0 ]]; then
        fail_test "the script finished with exit status ${tc_ret}, expected 0"
    fi
    if [[ -z ${tc_tag_hash} ]]; then
        fail_test "tag ${tc_tag@Q} not found on origin"
    fi
    if [[ -z ${tc_branch_hash} ]]; then
        fail_test "branch ${tc_branch@Q} not found on origin"
    fi
    GIT_PAGER= vc git show "${tc_tag_hash}"
    GIT_PAGER= vc git show "${tc_branch_hash}"
    if [[ ${tc_tag_hash} = "${tc_branch_hash}" ]]; then
        fail_test "tag pushed to the branch, while it should not be"
    fi
    log_test "OK"
)

function nightly_not_HEAD() (
    local build_type=${1}; shift
    local checkout_type=${1}; shift

    if [[ ${checkout_type} = 'fetch_head' ]]; then
        log_test 'skipping, fetch_head checkout type sidesteps the issue'
        return
    fi

    setup_cleanup_trap

    local tc_branch tc_script tc_tag

    git_wt_setup_open "${build_type}" 'nightly' 'fail-if-reached' tc_branch tc_script tc_tag

    log_test "creating a commit, pushing it to remote and resetting to HEAD^ locally"
    local tmpfile=$(mktemp testfile-XXXXXXXX)
    echo 'foo' >"${tmpfile}"
    git add "${tmpfile}"
    git commit -m 'stuff'
    git push --set-upstream origin "${tc_branch}"
    add_cleanup "log_test 'removing remote branch '${tc_branch@Q}; git push --delete origin ${tc_branch@Q}"
    git reset --hard HEAD^

    local -i tc_ret=0
    local tc_tag_hash tc_branch_hash
    git_wt_setup_close_and_run "${tc_branch}" "${tc_script}" "${tc_tag}" "${checkout_type}" tc_ret tc_tag_hash tc_branch_hash

    if [[ tc_ret -eq 0 ]]; then
        fail_test 'the script finished with exit status 0, expected non-zero'
    fi
    if [[ -n ${tc_tag_hash} ]]; then
        fail_test "tag ${tc_tag@Q} found on origin, but should not be"
    fi
    if [[ -z ${tc_branch_hash} ]]; then
        fail_test "branch ${tc_branch@Q} not found on origin"
    fi
    log_test "OK"
)

function nightly_HEAD_no_tags() (
    local build_type=${1}; shift
    local checkout_type=${1}; shift

    setup_cleanup_trap

    local tc_branch tc_script tc_tag

    git_wt_setup_open "${build_type}" 'nightly' 'fail-if-reached' tc_branch tc_script tc_tag

    log_test "creating a commit and pushing it to remote"
    local tmpfile=$(mktemp testfile-XXXXXXXX)
    echo 'foo' >"${tmpfile}"
    git add "${tmpfile}"
    git commit -m 'stuff'
    git push --set-upstream origin "${tc_branch}"
    add_cleanup "log_test 'removing remote branch '${tc_branch@Q}; git push --delete origin ${tc_branch@Q}"

    local -i tc_ret=0
    local tc_tag_hash tc_branch_hash
    git_wt_setup_close_and_run "${tc_branch}" "${tc_script}" "${tc_tag}" "${checkout_type}" tc_ret tc_tag_hash tc_branch_hash

    if [[ tc_ret -ne 0 ]]; then
        fail_test "the script finished with exit status ${tc_ret}, expected 0"
    fi
    if [[ -z ${tc_tag_hash} ]]; then
        fail_test "tag ${tc_tag@Q} not found on origin"
    fi
    if [[ -z ${tc_branch_hash} ]]; then
        fail_test "branch ${tc_branch@Q} not found on origin"
    fi
    GIT_PAGER= vc git show "${tc_tag_hash}"
    GIT_PAGER= vc git show "${tc_branch_hash}"
    if [[ ${tc_tag_hash} != "${tc_branch_hash}" ]]; then
        fail_test "tag not pushed to the branch, while it should be"
    fi
    log_test "OK"
)

function nightly_HEAD_no_nightly_tag() (
    local build_type=${1}; shift
    local checkout_type=${1}; shift

    setup_cleanup_trap

    local tc_branch tc_script tc_tag

    git_wt_setup_open "${build_type}" 'nightly' 'fail-if-reached' tc_branch tc_script tc_tag

    log_test "creating a commit, tagging it with a non-nightly tag and pushing them to remote"
    local tmpfile=$(mktemp testfile-XXXXXXXX)
    local channel=${tc_tag##-*} rest=${tc_tag%*-}
    local version=${rest##-*}
    local custom_tag=${channel}-${version}-some-custom-stuff
    echo 'foo' >"${tmpfile}"
    git add "${tmpfile}"
    git commit -m 'stuff'
    git tag "${custom_tag}"
    add_cleanup "log_test 'removing local tag '${custom_tag@Q}; git tag -d ${custom_tag@Q}"
    git push --set-upstream origin "${tc_branch}"
    add_cleanup "log_test 'removing remote branch '${tc_branch@Q}; git push --delete origin ${tc_branch@Q}"
    git push origin "${custom_tag}"
    add_cleanup "log_test 'removing remote tag '${custom_tag@Q}; git push --delete origin ${custom_tag@Q}"

    local -i tc_ret=0
    local tc_tag_hash tc_branch_hash
    git_wt_setup_close_and_run "${tc_branch}" "${tc_script}" "${tc_tag}" "${checkout_type}" tc_ret tc_tag_hash tc_branch_hash

    if [[ tc_ret -ne 0 ]]; then
        fail_test "the script finished with exit status ${tc_ret}, expected 0"
    fi
    if [[ -z ${tc_tag_hash} ]]; then
        fail_test "tag ${tc_tag@Q} not found on origin"
    fi
    if [[ -z ${tc_branch_hash} ]]; then
        fail_test "branch ${tc_branch@Q} not found on origin"
    fi
    GIT_PAGER= vc git show "${tc_tag_hash}"
    GIT_PAGER= vc git show "${tc_branch_hash}"
    if [[ ${tc_tag_hash} != "${tc_branch_hash}" ]]; then
        fail_test "tag not pushed to the branch, while it should be"
    fi
    log_test "OK"
)

function another_nightly_tag() {
    local tag=${1}; shift
    local -n tag_ref=${1}; shift

    local new_tag_prefix=${tag}
    new_tag_prefix=${new_tag_prefix%-*} # cut off -hhmm
    new_tag_prefix=${new_tag_prefix%-*} # cut off -yyyymmdd

    local -i random_part
    local new_tag
    while :; do
        new_tag=${new_tag_prefix}
        random_digits 8 random_part
        new_tag+=-${random_part}
        random_digits 4 random_part
        new_tag+=-${random_part}
        if [[ ${new_tag} != ${tag} ]]; then
            break
        fi
    done
    tag_ref=${new_tag}
}

function nightly_HEAD_nightly_tag_with_diff() (
    local build_type=${1}; shift
    local checkout_type=${1}; shift

    setup_cleanup_trap

    local tc_branch tc_script tc_tag

    git_wt_setup_open "${build_type}" 'nightly' 'fail-if-reached' tc_branch tc_script tc_tag

    log_test "creating a commit, tagging it with a nightly tag and pushing them to remote, making local uncommited changes"
    local tmpfile=$(mktemp testfile-XXXXXXXX)
    local prev_nightly_tag
    another_nightly_tag "${tc_tag}" prev_nightly_tag
    echo 'foo' >"${tmpfile}"
    git add "${tmpfile}"
    git commit -m 'stuff'
    git tag "${prev_nightly_tag}"
    add_cleanup "log_test 'removing local tag '${prev_nightly_tag@Q}; git tag -d ${prev_nightly_tag@Q}"
    git push --set-upstream origin "${tc_branch}"
    add_cleanup "log_test 'removing remote branch '${tc_branch@Q}; git push --delete origin ${tc_branch@Q}"
    git push origin "${prev_nightly_tag}"
    add_cleanup "log_test 'removing remote tag '${prev_nightly_tag@Q}; git push --delete origin ${prev_nightly_tag@Q}"
    echo 'bar' >"${tmpfile}"

    local -i tc_ret=0
    local tc_tag_hash tc_branch_hash
    git_wt_setup_close_and_run "${tc_branch}" "${tc_script}" "${tc_tag}" "${checkout_type}" tc_ret tc_tag_hash tc_branch_hash

    if [[ tc_ret -eq 0 ]]; then
        fail_test 'the script finished with exit status 0, expected non-zero'
    fi
    if [[ -n ${tc_tag_hash} ]]; then
        fail_test "tag ${tc_tag@Q} found on origin, but should not be"
    fi
    if [[ -z ${tc_branch_hash} ]]; then
        fail_test "branch ${tc_branch@Q} not found on origin"
    fi
    log_test "OK"
)

function nightly_HEAD_nightly_tag_images_exist() (
    local build_type=${1}; shift
    local checkout_type=${1}; shift

    setup_cleanup_trap

    local tc_branch tc_script tc_tag

    git_wt_setup_open "${build_type}" 'nightly' 'yes' tc_branch tc_script tc_tag

    log_test "creating a commit, tagging it with a nightly tag and pushing them to remote, assuming the images for the tag exist"
    local tmpfile=$(mktemp testfile-XXXXXXXX)
    local prev_nightly_tag
    another_nightly_tag "${tc_tag}" prev_nightly_tag
    echo 'foo' >"${tmpfile}"
    git add "${tmpfile}"
    git commit -m 'stuff'
    git tag "${prev_nightly_tag}"
    add_cleanup "log_test 'removing local tag '${prev_nightly_tag@Q}; git tag -d ${prev_nightly_tag@Q}"
    git push --set-upstream origin "${tc_branch}"
    add_cleanup "log_test 'removing remote branch '${tc_branch@Q}; git push --delete origin ${tc_branch@Q}"
    git push origin "${prev_nightly_tag}"
    add_cleanup "log_test 'removing remote tag '${prev_nightly_tag@Q}; git push --delete origin ${prev_nightly_tag@Q}"

    local old_branch_hash
    old_branch_hash=$(git rev-parse "${tc_branch}")

    local -i tc_ret=0
    local tc_tag_hash tc_branch_hash
    git_wt_setup_close_and_run "${tc_branch}" "${tc_script}" "${tc_tag}" "${checkout_type}" tc_ret tc_tag_hash tc_branch_hash

    if [[ tc_ret -ne 0 ]]; then
        fail_test "the script finished with exit status ${tc_ret}, expected 0"
    fi
    if [[ -n ${tc_tag_hash} ]]; then
        fail_test "tag ${tc_tag@Q} found on origin, while it should not be"
    fi
    if [[ -z ${tc_branch_hash} ]]; then
        fail_test "branch ${tc_branch@Q} not found on origin"
    fi
    if [[ ${old_branch_hash} != "${tc_branch_hash}" ]]; then
        fail_test "the branch has changed, while it should not"
    fi
    log_test "OK"
)

function nightly_HEAD_nightly_tag_images_not_exist() (
    local build_type=${1}; shift
    local checkout_type=${1}; shift

    setup_cleanup_trap

    local tc_branch tc_script tc_tag

    git_wt_setup_open "${build_type}" 'nightly' 'no' tc_branch tc_script tc_tag

    log_test "creating a commit, tagging it with a nightly tag and pushing them to remote, assuming the  images for the tag do not exist"
    local tmpfile=$(mktemp testfile-XXXXXXXX)
    local prev_nightly_tag
    another_nightly_tag "${tc_tag}" prev_nightly_tag
    echo 'foo' >"${tmpfile}"
    git add "${tmpfile}"
    git commit -m 'stuff'
    git tag "${prev_nightly_tag}"
    add_cleanup "log_test 'removing local tag '${prev_nightly_tag@Q}; git tag -d ${prev_nightly_tag@Q}"
    git push --set-upstream origin "${tc_branch}"
    add_cleanup "log_test 'removing remote branch '${tc_branch@Q}; git push --delete origin ${tc_branch@Q}"
    git push origin "${prev_nightly_tag}"
    add_cleanup "log_test 'removing remote tag '${prev_nightly_tag@Q}; git push --delete origin ${prev_nightly_tag@Q}"

    local -i tc_ret=0
    local tc_tag_hash tc_branch_hash
    git_wt_setup_close_and_run "${tc_branch}" "${tc_script}" "${tc_tag}" "${checkout_type}" tc_ret tc_tag_hash tc_branch_hash

    if [[ tc_ret -ne 0 ]]; then
        fail_test "the script finished with exit status ${tc_ret}, expected 0"
    fi
    if [[ -z ${tc_tag_hash} ]]; then
        fail_test "tag ${tc_tag@Q} not found on origin, while it should be"
    fi
    if [[ -z ${tc_branch_hash} ]]; then
        fail_test "branch ${tc_branch@Q} not found on origin"
    fi
    if [[ ${tc_tag_hash} != "${tc_branch_hash}" ]]; then
        fail_test "tag not pushed to the branch, while it should be"
    fi
    log_test "OK"
)

mkdir -p "${LOGDIR}"

declare -g START_AT_TC_NAME=test_${START_AT_TC}__build_${START_AT_BT}__checkout_${START_AT_CT}

for tc in "${TESTCASES[@]}"; do
    for bt in "${BUILD_TYPES[@]}"; do
        for ct in "${CHECKOUT_TYPES[@]}"; do
            tc_name=test_${tc}__build_${bt}__checkout_${ct}
            if [[ -n ${START_AT_TC_NAME} ]]; then
                if [[ ${START_AT_TC_NAME} != "${tc_name}" ]]; then
                    continue
                fi
                START_AT_TC_NAME=''
            fi
            # redirect testcase's stdout and stderr to log file,
            # testcase's fd 3 to our stdout
            echo "testcase: ${tc}  build type: ${bt}  checkout type: ${ct}"
            "${tc}" "${bt}" "${ct}" 3>&1 1>"${LOGDIR}/${tc_name}" 2>&1
            unset tc_name
        done
    done
done
unset tc bt ct

echo 'ALL DONE'
