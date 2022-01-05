#!/bin/bash

if [ -n "${SDK_USER_ID:-}" ] ; then
    usermod -u $SDK_USER_ID sdk
fi
if [ -n "${SDK_GROUP_ID:-}" ] ; then
    groupmod -g $SDK_GROUP_ID sdk
fi

chown -R sdk:sdk /home/sdk

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
