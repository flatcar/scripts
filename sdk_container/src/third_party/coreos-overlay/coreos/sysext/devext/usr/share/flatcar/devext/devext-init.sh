#!/bin/bash

set -euo pipefail

version="$(source /usr/lib/extension-release.d/extension-release.devext \
           && echo "$VERSION_ID")"

basedir="/usr/share/flatcar/devext"
vardir="/var/devext/${version}"

for dir in var/db/pkg \
           var/lib/portage \
           etc/portage; do

    workdir="${vardir}/.$(basename "${dir}")-work"
    writedir="${vardir}/${dir}"
    mkdir -p "/${dir}" "${writedir}" "${workdir}"

    srcdir="${basedir}/${dir}"
    mount -t overlay \
        -o "lowerdir=${srcdir},upperdir=${writedir},workdir=${workdir}" \
        "/usr/share/flatcar/devext/${dir}" "/${dir}"
done

# set up mutable /usr
mkdir -p "${vardir}/usr" \
         "/var/lib/extensions.mutable/"

ln -s "${vardir}/usr" "/var/lib/extensions.mutable/"

if ! touch /usr/dev-mode; then
    systemctl reload systemd-sysext.service
    touch /usr/dev-mode
fi
