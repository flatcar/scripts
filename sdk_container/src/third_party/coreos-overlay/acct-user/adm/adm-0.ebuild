# Copyright 2024 Flatcar Maintainers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

ACCT_USER_ID=3
ACCT_USER_ENFORCE_ID=x
ACCT_USER_GROUPS=( adm sys disk)

acct-user_add_deps
