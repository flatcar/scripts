#!/bin/bash

set -euo pipefail

source "${GHA_SCRIPTS_DIR}/.github/workflows/common.sh"
prepare_git_repo

: "${BRANCH:?Set BRANCH to the Gentoo upstream branch.}"

latest_commit=$(git rev-parse HEAD)
echo "LATEST_COMMIT=${latest_commit}" >>"${GITHUB_OUTPUT}"
echo "SHORT_COMMIT=${latest_commit:0:12}" >>"${GITHUB_OUTPUT}"

tracking_refspec='+refs/heads/tracking-*:refs/remotes/origin/tracking-*'
branch_refspec="+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}"
depth=1000
# Including the base branch also makes this fetch succeed when no tracking branches exist.
git fetch --filter=blob:none --no-tags --no-recurse-submodules --depth="${depth}" \
    origin "${branch_refspec}" "${tracking_refspec}"
tracking_branches=$(git for-each-ref --format='%(objectname) %(refname:strip=3)' refs/remotes/origin/)

while read -r previous_commit branch; do
    [[ "${branch}" == tracking-* ]] || continue

    history_size=0
    while true; do
        if base=$(git merge-base "${latest_commit}" "${previous_commit}"); then
            break
        else
            status=$?
            if [[ "${status}" != 1 ]]; then
                exit "${status}"
            fi
        fi
        current_history_size=$(git rev-list --count "${latest_commit}" "${previous_commit}")
        if [[ "${current_history_size}" == "${history_size}" ||
              $(git rev-parse --is-shallow-repository) == false ]]; then
            echo "::warning::Cannot rebase ${branch}: no common ancestor with ${BRANCH}; remote branch unchanged."
            continue 2
        fi
        history_size="${current_history_size}"
        # Deepen the original tips, not potentially rewritten remote branches.
        git fetch --filter=blob:none --no-tags --no-recurse-submodules --deepen="${depth}" \
            origin "${latest_commit}" "${previous_commit}"
        depth=$((depth * 2))
    done

    git checkout --no-track -b "${branch}" "${previous_commit}"
    if ! git rebase --onto "${latest_commit}" "${base}"; then
        if [[ -z $(git ls-files --unmerged) ]]; then
            echo "::error::Rebasing ${branch} failed without merge conflicts; inspect the Git error above."
            exit 1
        fi
        git rebase --abort
        echo "::warning::Cannot rebase ${branch} onto ${BRANCH}: resolve the conflicts manually; remote branch unchanged."
        continue
    fi
    if [[ $(git rev-parse HEAD) != "${previous_commit}" ]]; then
        git push --force-with-lease="refs/heads/${branch}:${previous_commit}" \
            origin "HEAD:refs/heads/${branch}"
    fi
done <<<"${tracking_branches}"
