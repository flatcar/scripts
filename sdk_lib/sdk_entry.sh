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

# SDK container is launched using the su command below, which does not preserve environment
# moreover, if multiple shells are attached to the same container,
# we want all of them to share the same value of the variable, therefore we need to save it in .bashrc
grep -q 'export MODULE_SIGNING_KEY_DIR' /home/sdk/.bashrc || {
    MODULE_SIGNING_KEY_DIR=$(su sdk -c "mktemp -d")
    if [[ ! "$MODULE_SIGNING_KEY_DIR" || ! -d "$MODULE_SIGNING_KEY_DIR" ]]; then
        echo "Failed to create temporary directory for secure boot keys."
    else
        echo "export MODULE_SIGNING_KEY_DIR='$MODULE_SIGNING_KEY_DIR'" >> /home/sdk/.bashrc
        echo "export MODULES_SIGN_KEY='${MODULE_SIGNING_KEY_DIR}/certs/modules.pem'" >> /home/sdk/.bashrc
        echo "export MODULES_SIGN_CERT='${MODULE_SIGNING_KEY_DIR}/certs/modules.pub.pem'" >> /home/sdk/.bashrc
    fi
}

grep -q 'export SYSEXT_SIGNING_KEY_DIR' /home/sdk/.bashrc || {
    SYSEXT_SIGNING_KEY_DIR=$(su sdk -c "mktemp -d")
    if [[ ! "$SYSEXT_SIGNING_KEY_DIR" || ! -d "$SYSEXT_SIGNING_KEY_DIR" ]]; then
        echo "Failed to create temporary directory for secure boot keys."
    else
        echo "export SYSEXT_SIGNING_KEY_DIR='$SYSEXT_SIGNING_KEY_DIR'" >> /home/sdk/.bashrc
    fi
    pushd "$SYSEXT_SIGNING_KEY_DIR"
    build_id=$(source "/mnt/host/source/.repo/manifests/version.txt"; echo "$FLATCAR_BUILD_ID")
    openssl req -new -nodes -utf8 \
        -x509 -batch -sha256 \
        -days 36000 \
        -outform PEM \
        -out sysexts.crt \
        -keyout sysexts.key \
        -newkey 4096 \
        -subj "/CN=Flatcar $build_id sysext signing key/" \
          || echo "Generating module signing key failed"
    popd
}

# This is ugly.
#   We need to sudo su - sdk -c so the SDK user gets a fresh login.
#    'sdk' is member of multiple groups, and plain docker USER only
#    allows specifying membership of a single group.
#    When a command is passed to the container, we run, respectively:
#    sudo su - sdk -c "<command>".
#   Then, we need to preserve whitespaces in arguments of commands
#    passed to the container, e.g.
#    ./update_chroot --toolchain_boards="amd64-usr arm64-usr".
#    This is done via a separate ".cmd" file since we have used up
#    our quotes for su -c "<cmd>" already.
if [ $# -gt 0 ] ; then
    cmd="/home/sdk/.cmd"
    echo -n "exec bash -l -i -c '" >"$cmd"
    for arg in "$@"; do
        echo -n "\"$arg\" " >>"$cmd"
    done
    echo "'" >>"$cmd"
    chmod 755 "$cmd"
    sudo su sdk -c "$cmd"
    rc=$?
    rm -f "$cmd"
    exit $rc
else
    exec sudo su -l sdk
fi
