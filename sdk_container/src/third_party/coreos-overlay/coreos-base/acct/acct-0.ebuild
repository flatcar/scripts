# Copyright (c) 2024 The Flatcar Maintainers.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION='Metapackage for pulling in user/group packages'
HOMEPAGE='https://www.flatcar.org/'

LICENSE='Apache-2.0'
SLOT='0'
KEYWORDS='amd64 arm64'

# No source directory.
S="${WORKDIR}"

# TODO: add all the stuff from coreos-overlay/acct-{group,user}

# Versions listed below are version of packages that shedded the
# modifications in their ebuilds.
RDEPEND="
	acct-group/bin
	acct-group/cdrw
	acct-group/console
	acct-group/core
	acct-group/daemon
	acct-group/dhcp
	acct-group/etcd
	acct-group/lock
	acct-group/lp
	acct-group/mem
	acct-group/news
	acct-group/nogroup
	acct-group/sudo
	acct-group/sys
	acct-group/syslog
	acct-group/systemd-bus-proxy
	acct-group/tcpdump
	acct-group/tlsdate

	acct-user/adm
	acct-user/bin
	acct-user/core
	acct-user/daemon
	acct-user/dhcp
	acct-user/docker
	acct-user/etcd
	acct-user/halt
	acct-user/lp
	acct-user/news
	acct-user/operator
	acct-user/shutdown
	acct-user/sync
	acct-user/syslog
	acct-user/systemd-bus-proxy
	acct-user/tcpdump
	acct-user/tlsdate
	acct-user/uucp
"
