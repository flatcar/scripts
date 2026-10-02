#!/bin/bash

if [ -n "${SDK_USER_ID:-}" ] ; then
    # If the "core" user from /usr/share/baselayout/passwd has the same ID, allow to take it instead
    usermod --non-unique -u $SDK_USER_ID sdk
fi
if [ -n "${SDK_GROUP_ID:-}" ] ; then
    groupmod --non-unique -g $SDK_GROUP_ID sdk
fi

chown -R sdk:sdk /home/sdk

# Fix up SDK repo configuration to use the new coreos-overlay name.
sed -i -r 's/^\[coreos\]/[coreos-overlay]/' /etc/portage/repos.conf/coreos.conf 2>/dev/null
sed -i -r '/^masters =/s/\bcoreos(\s|$)/coreos-overlay\1/g' /usr/local/portage/crossdev/metadata/layout.conf 2>/dev/null

# Check if the OS image version we're working on is newer than
#  the SDK container version and if it is, update the boards
#  chroot portage conf to point to the correct binhost.
(
    source /etc/lsb-release # SDK version in DISTRIB_RELEASE
    source /mnt/host/source/.repo/manifests/version.txt # OS image version in FLATCAR_VERSION_ID
    version="${FLATCAR_VERSION_ID}"

    # If this is a nightly build tag we can use pre-built binaries directly from the
    #  build cache.
    if [[ "${FLATCAR_BUILD_ID}" =~ ^nightly-.*$ ]] ; then
        version="${FLATCAR_VERSION_ID}+${FLATCAR_BUILD_ID}"
    fi

    if [ "${version}" != "${DISTRIB_RELEASE}" ] ; then
        for target in amd64-usr arm64-usr; do
            if [ ! -d "/build/$target" ] ; then
                continue
            fi
            if [ -f "/build/$target/etc/target-version.txt" ] ; then
                source "/build/$target/etc/target-version.txt"
                if [ "${TARGET_FLATCAR_VERSION}" = "${version}" ] ; then
                    continue # already updated
                fi
            fi

            echo
            echo "Updating board support in '/build/${target}' to use package cache for version '${version}'"
            echo "---"
            sudo su sdk -l -c "/home/sdk/trunk/src/scripts/setup_board --board='$target' --regen_configs_only"
            echo "TARGET_FLATCAR_VERSION='${version}'" | sudo tee "/build/$target/etc/target-version.txt" >/dev/null
        done
    fi
)

# We need to sudo -u sdk with bash -l so that the SDK user gets a fresh login.
# sudo has an -i option to get a login shell, but that cannot be combined with
# -E to preserve the environment. We already have a relatively clean environment
# inside the container, but we want to preserve variables passed through Docker.
exec sudo -u sdk -EH bash -l -i ${1+-c '"${@}"' -- "${@}"}
