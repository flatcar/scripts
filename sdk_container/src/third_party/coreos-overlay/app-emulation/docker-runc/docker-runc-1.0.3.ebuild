# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

GITHUB_URI="github.com/opencontainers/runc"
COREOS_GO_PACKAGE="${GITHUB_URI}"
COREOS_GO_VERSION="go1.17"
# the commit of runc that docker uses.
# see https://github.com/docker/docker-ce/blob/v19.03.15/components/engine/hack/dockerfile/install/runc.installer#L4
COMMIT_ID="e4bccdbd64361ac5ea8ba90bb8845add78f957a6"

inherit eutils flag-o-matic coreos-go vcs-snapshot

SRC_URI="https://${GITHUB_URI}/archive/${COMMIT_ID}.tar.gz -> ${P}.tar.gz"
KEYWORDS="amd64 arm64"

DESCRIPTION="runc container cli tools (docker fork)"
HOMEPAGE="http://runc.io"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="ambient apparmor hardened +seccomp selinux"

RDEPEND="
	apparmor? ( sys-libs/libapparmor )
	seccomp? ( sys-libs/libseccomp )
"

S=${WORKDIR}/${P}/src/${COREOS_GO_PACKAGE}

RESTRICT="test"

src_unpack() {
	mkdir -p "${S}"
	tar --strip-components=1 -C "${S}" -xf "${DISTDIR}/${A}"
}

PATCHES=(
	"${FILESDIR}/0001-Delay-unshare-of-clone-newipc-for-selinux.patch"
)

src_compile() {
	# Taken from app-emulation/docker-1.7.0-r1
	export CGO_CFLAGS="-I${SYSROOT}/usr/include"
	export CGO_LDFLAGS="$(usex hardened '-fno-PIC ' '')
		-L${SYSROOT}/usr/$(get_libdir)"

	# build up optional flags
	local options=(
		$(usex ambient 'ambient' '')
		$(usex apparmor 'apparmor' '')
		$(usex seccomp 'seccomp' '')
		$(usex selinux 'selinux' '')
	)

	GOPATH="${WORKDIR}/${P}" emake BUILDTAGS="${options[*]}" \
		VERSION=1.0.3+dev.docker-20.10 \
		COMMIT="${COMMIT_ID}"
}

src_install() {
	dobin runc
}
