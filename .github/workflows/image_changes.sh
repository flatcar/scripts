#!/bin/bash

#set -x
set -euo pipefail

source ci-automation/image_changes.sh

# Callback invoked by run_image_changes_job, read its docs to learn
# about the details about the callback.
function github_ricj_callback() {
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
}

arch=${1}; shift
mode=${1}; shift
report_file_name="image-changes-reports-${mode}.txt"

run_image_changes_job "${arch}" "${mode}" "${report_file_name}" '../flatcar-build-scripts' github_ricj_callback
