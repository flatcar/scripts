#!/bin/bash

set -x
set -euo pipefail

mode=${1}; shift
case ${mode} in
    release|nightly)
        :
        ;;
    *)
        echo "invalid mode ${mode@Q}" >&2
        exit 1
        ;;
esac

git_tag_for_mode="git_tag_for_${mode}"
prepare_env_vars_and_params_for_mode="prepare_env_vars_and_params_for_${mode}"
report_file_name="image-changes-reports-${mode}.txt"

source ci-automation/image_changes.sh

git_tag=''
"${git_tag_for_mode}" . git_tag

declare -a var_names=(
    package_diff_env package_diff_params
    size_changes_env size_changes_params
    show_changes_env show_changes_params
)
declare -a "${var_names[@]}"
version_description=''
var_names+=( version_description )

"${prepare_env_vars_and_params_for_mode}" "${arch}" "${git_tag}" "${var_names[@]}"

package_diff_env+=(
    "FROM_B=file://${PWD}/artifacts/images"
    # BOARD_B and CHANNEL_B are unused.
)
package_diff_params+=(
    # The package-diff script appends version to the file
    # URL, but the directory with the image has no version
    # component at its end, so we use . as a version.
    '.'
)
# Nothing to add to size changes env.
size_changes_params+=(
    "local:${PWD}/artifacts/images"
)
show_changes_env+=(
    # Override the default locations of repositories.
    "SCRIPTS_REPO=."
    "COREOS_OVERLAY_REPO=../coreos-overlay"
    "PORTAGE_STABLE_REPO=../portage-stable"
)
show_changes_params+=(
    # We may not have a tag handy, so we tell show-changes
    # to use git HEAD as a reference to new changelog
    # entries.
    'NEW_VERSION=HEAD'
)

declare -a oemids base_sysexts
get_oem_id_list . "${arch}" oemids
get_base_sysext_list . "${arch}" base_sysexts
generate_image_changes_report \
    "${version_description}" "${report_file_name}" "../flatcar-build-scripts" \
    "${package_diff_env[@]}" --- "${package_diff_params[@]}" -- \
    "${size_changes_env[@]}" --- "${size_changes_params[@]}" -- \
    "${show_changes_env[@]}" --- "${show_changes_params[@]}" -- \
    "${oemids[@]}" -- "${base_sysexts[@]}"
