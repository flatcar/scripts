# Copyright (c) 2017-2018 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Packages to be installed in a torcx image for Docker"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64"

# Explicitly list all packages that will be built into the image.
RDEPEND="
	~app-containers/docker-20.10.24
	~app-containers/docker-cli-20.10.24
	~app-containers/containerd-1.6.21
	~app-containers/docker-proxy-0.8.0_p20230118
	~app-containers/runc-1.1.7
	~dev-libs/libltdl-2.4.7
	~sys-process/tini-0.19.0
"

S="${WORKDIR}"

src_install() {
	insinto /.torcx
	newins "${FILESDIR}/${P}-manifest.json" manifest.json

	# Enable the Docker socket by default.
	local unitdir=/usr/lib/systemd/system
	dosym ../docker.socket "${unitdir}/sockets.target.wants/docker.socket"
}
