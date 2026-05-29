#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

install() {
    inst_script "${moddir}/acl-selinux-toggle.sh" \
                "/usr/bin/acl-selinux-toggle"

    inst_simple "${moddir}/acl-selinux-toggle.service" \
                "${systemdsystemunitdir}/acl-selinux-toggle.service"

    # Manually enable the unit — dracut does not process [Install] sections.
    mkdir -p "${initdir}/${systemdsystemunitdir}/initrd.target.wants"
    ln -sf "../acl-selinux-toggle.service" \
        "${initdir}/${systemdsystemunitdir}/initrd.target.wants/acl-selinux-toggle.service"
}
