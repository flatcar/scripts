# Copyright 2024 Flatcar Maintainers
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

ACCT_USER_ID=4
ACCT_USER_ENFORCE_ID=x
ACCT_USER_GROUPS=( lp )

acct-user_add_deps
