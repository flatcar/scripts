#!/bin/bash

if [[ -z ${WORKAROUND_WORKTREES_SH_INCLUDED:-} ]]; then

WORKAROUND_WORKTREES_SH_INCLUDED=x

# 1 - path to a git repository
# 2 - name of a variable that contain a path to the main repo
# 3 - name of a variable that will be a linked repos map (names to paths)
function discover_repo_layout {
    local path=${1}; shift
    local -n main_repo_ref=${1}; shift
    local -n linked_repos_map_ref=${1}; shift

    local dot_git=${path}/.git
    local main_repo_path
    if [[ -d ${dot_git} ]]; then
        main_repo_path=$(realpath "${path}")
    elif [[ -f ${dot_git} ]]; then
        main_repo_path=$(head -n1 "${dot_git}")
        main_repo_path=${main_repo_path#* }
        local found base
        found=
        while [[ ${main_repo_path%/*} != "${main_repo_path}" ]]; do
            base=${main_repo_path##*/}
            main_repo_path=${main_repo_path%/*}
            if [[ ${base} = '.git' ]]; then
                found=x
                break
            fi
        done
        if [[ -z ${found} ]]; then
            echo "${FUNCNAME[0]}: possibly corrupted linked repo .git file ${dot_git@Q}, could not figure out path to the main repo" >&2
            return 1
        fi
        unset found base
    else
        echo "${FUNCNAME[0]}: ${path@Q} does not seem to be a git repo" >&2
        return 1
    fi
    main_repo_ref=${main_repo_path}
    linked_repos_map_ref=()
    local in_worktree_gitdir_file in_worktree_gitdir_dir
    local bogus entry linked_repo_name linked_repo_path
    while read -r in_worktree_gitdir_file; do
        in_worktree_gitdir_dir=${in_worktree_gitdir_file%/gitdir}
        bogus=
        for entry in commondir HEAD index; do
            if [[ ! -e ${in_worktree_gitdir_dir}/${entry} ]]; then
                bogus=x
                break
            fi
        done
        if [[ ! -d ${in_worktree_gitdir_dir}/logs ]]; then
            bogus=x
        fi
        if [[ -n ${bogus} ]]; then
            echo "${FUNCNAME[0]}: ${in_worktree_gitdir_file@Q} is bogus, skipping" >&2
            continue
        fi
        linked_repo_name=${in_worktree_gitdir_file}
        linked_repo_name=${linked_repo_name#"${main_repo_path}/.git/worktrees/"}
        linked_repo_name=${linked_repo_name%/gitdir}
        linked_repo_path=$(cat "${in_worktree_gitdir_file}")
        linked_repo_path=${linked_repo_path%/.git}
        linked_repos_map_ref["${linked_repo_name}"]=${linked_repo_path}
    done < <(find "${main_repo_path}/.git/worktrees" -name gitdir)
    return 0
}

# 1 - path to repo
# 2 - main repo path
# 3 - name of a variable that is a linked repos map (names to paths)
# 4 - name of a variable that will contain the linked repo name,
#     prefixed with "ex-"; will empty if not found, will be just "ex-" for main repo
function linked_repo_name {
    local path=${1}; shift
    local main_repo_path=${1}; shift
    local -n linked_repos_map_ref=${1}; shift
    local -n repo_name_ref=${1}; shift

    repo_name_ref=''
    # git is using real paths
    local real_path
    real_path=$(realpath "${path}")
    if [[ ${real_path} = "${main_repo_path}" ]]; then
        repo_name_ref='ex-'
    else
        local name linked_path
        for name in "${!linked_repos_map_ref[@]}"; do
            linked_path=${linked_repos_map_ref["${name}"]}
            if [[ ${linked_path} == "${real_path}" ]]; then
                repo_name_ref="ex-${name}"
                break
            fi
        done
    fi
}

# 1 - base directory in SDK
# 2 - name of a variable that is an overrides map (names to paths),
#     names should be "ex-${name}", for main repo - just "ex-"
# 3 - name of a variable that will contain path to main repo inside SDK
# 4 - name of a variable that will be a linked repos map inside SDK (names to paths)
# @ - linked repo names
function repo_layout_inside_sdk {
    local base_directory_sdk=${1}; shift
    local -n overrides_map_ref=${1}; shift
    local -n main_repo_path_sdk_ref=${1}; shift
    local -n linked_repos_sdk_map_ref=${1}; shift
    # rest are names

    local override=${overrides_map_ref['ex-']:-}
    if [[ -n ${override} ]]; then
        main_repo_path_sdk_ref=${override}
    else
        main_repo_path_sdk_ref=${base_directory_sdk}/main-repo
    fi

    local name
    linked_repos_sdk_map_ref=()
    for name; do
        override=${overrides_map_ref["ex-${name}"]:-}
        if [[ -n ${override} ]]; then
            linked_repos_sdk_map_ref["${name}"]=${override}
        else
            linked_repos_sdk_map_ref["${name}"]=${base_directory_sdk}/linked/${name}
        fi
    done
}

# 1 - main repo path
# 2 - main repo path in SDK
# 3 - name of a variable that is a linked repos map (names to paths)
# 4 - name of a variable that is a linked repos map in SDK (names to paths)
# 5 - name of a variable that will be a volumes array
function repo_layouts_to_docker_volumes {
    local main_repo_path=${1}; shift
    local main_repo_path_sdk=${1}; shift
    local -n linked_repos_map_ref=${1}; shift
    local -n linked_repos_sdk_map_ref=${1}; shift
    local -n volumes_ref=${1}; shift

    volumes_ref=( -v "${main_repo_path}:${main_repo_path_sdk}" )
    local name path path_sdk
    for name in "${!linked_repos_map_ref[@]}"; do
        path=${linked_repos_map_ref["${name}"]}
        path_sdk=${linked_repos_sdk_map_ref["${name}"]}
        volumes_ref+=( -v "${path}:${path_sdk}" )
    done
}

# 1 - main repo path (usually the one in SDK)
# 2 - name of a variable that is a linked repos map (usually the one in SDK) (names to paths)
# 3 - path to file with replacements
function repo_layout_to_replacements {
    local main_repo_path=${1}; shift
    local -n linked_repos_map_ref=${1}; shift
    local replacements_path=${1}; shift

    {
        cat <<'EOF'
if [[ ${1} = 'local' ]]; then
    local -A REPLACEMENTS
fi

REPLACEMENTS=(
EOF
        local -a pairs
        pairs=()
        local name path
        for name in "${!linked_repos_map_ref[@]}"; do
            path=${linked_repos_map_ref["${name}"]}
            pairs+=(
                "${main_repo_path}/.git/worktrees/${name}/gitdir" "${path}/.git"
                "${path}/.git" "gitdir: ${main_repo_path}/.git/worktrees/${name}"
            )
        done
        printf '    [%s]=%s\n' "${pairs[@]@Q}"
        cat <<'EOF'
)
EOF
    } >"${replacements_path}"
}

# 1 - path to replacements file (to be sourced)
# 2 - path a scrap directory
# 3 - path to undo file
function replacements_to_bind_mounts {
    local replacements_path=${1}; shift
    local scrap_dir=${1}; shift
    local undo_path=${1}; shift

    # Brings in REPLACEMENTS.
    source "${replacements_path}" 'local'

    local -a paths=()

    local path contents scrap_file ug
    for path in "${!REPLACEMENTS[@]}"; do
        contents=${REPLACEMENTS["${path}"]}
        scrap_file=$(mktemp --tmpdir="${scrap_dir}" scrap-XXXXXXXXXX)
        ug=$(stat --format='%u:%g' "${path}")
        echo "${contents}" >"${scrap_file}"
        sudo chown "${ug}" "${scrap_file}"
        sudo mount --bind "${scrap_file}" "${path}"
        rm -f "${scrap_file}"
        paths+=( "${path}" )
    done

    {
        echo "sudo umount ${paths[*]@Q}"
    }>"${undo_path}"
}

fi
