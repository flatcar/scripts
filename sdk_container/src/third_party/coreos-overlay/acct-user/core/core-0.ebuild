# Copyright 2021-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

ACCT_USER_ID=500
ACCT_USER_ENFORCE_ID=yes
ACCT_USER_SHELL="/bin/bash"
ACCT_USER_HOME="/home/core"
ACCT_USER_GROUPS=( core wheel docker systemd-journal portage )

acct-user_add_deps
