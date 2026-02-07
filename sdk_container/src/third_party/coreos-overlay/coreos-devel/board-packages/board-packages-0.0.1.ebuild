# Copyright 2013 The CoreOS Authors
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=8

DESCRIPTION="Meta ebuild for building all binary packages"
HOMEPAGE="https://www.flatcar.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64"

RDEPEND="
	app-containers/containerd
	app-containers/docker
	app-containers/docker-buildx
	app-containers/docker-cli
	coreos-base/coreos
	coreos-base/coreos-dev
	sys-boot/grub
	sys-boot/shim
	sys-boot/shim-signed
"
