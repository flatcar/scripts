#!/bin/bash

# Prints the following github outputs based on channel named passed to
# the script as a parameter.
#
# BRANCH is a name of the git branch related to the passed channel.
#
# SKIP tells whether the rest of the steps should be skipped, will be
# either 0 or 1.
#
# LINK is a link to release mirror for the following channel. Will be
# empty for main channel.
#
# LABEL is going to be mostly the same as the channel name, except
# that lts-old will be labeled as lts.

set -euo pipefail

if [[ ${#} -ne 1 ]]; then
    echo "Expected a channel name as a parameter" >&2
    exit 1
fi

channel_name="${1}"
skip=0
link=''
branch=''
label=''
case "${channel_name}" in
    main)
        branch='main'
        ;;
    lts-old)
        curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 'https://lts.release.flatcar-linux.net/lts-info'
        if [[ $(grep -e ':supported' lts-info | wc -l) -le 1 ]]; then
            # Only one supported LTS, skip this workflow run
            # as 'lts' matrix branch will handle updating the only
            # supported LTS.
            skip=1
        else
            line=$(grep -e ':supported' lts-info | sort -V | head -n 1)
            major=$(awk -F: '{print $1}' <<<"${line}")
            year=$(awk -F: '{print $2}' <<<"${line}")
            branch="flatcar-${major}"
            link="https://lts.release.flatcar-linux.net/amd64-usr/current-${year}"
            label='lts'
        fi
        rm -f lts-info
        ;;
    alpha|beta|stable|lts)
        link="https://${channel_name}.release.flatcar-linux.net/amd64-usr/current"
        major=$(curl -sSL "${link}/version.txt" | awk -F= '/FLATCAR_BUILD=/{ print $2 }')
        branch="flatcar-${major}"
        ;;
    *)
        echo "Unknown channel '${channel_name}'" >&2
        exit 1
esac

if [[ -z "${label}" ]]; then
    label="${channel_name}"
fi

echo "BRANCH=${branch}" >>"${GITHUB_OUTPUT}"
echo "SKIP=${skip}" >>"${GITHUB_OUTPUT}"
echo "LINK=${link}" >>"${GITHUB_OUTPUT}"
echo "LABEL=${label}" >>"${GITHUB_OUTPUT}"
