# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGIT_REPO_URI="https://github.com/flatcar/coreos-cloudinit.git"
COREOS_GO_PACKAGE="github.com/flatcar/coreos-cloudinit"
COREOS_GO_GO111MODULE="on"
inherit git-r3 systemd toolchain-funcs udev coreos-go

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	EGIT_COMMIT="1c1d7f4ae6b933350d7fd36e882dda170123cccc" # main
	KEYWORDS="amd64 arm64"
fi

DESCRIPTION="coreos-cloudinit"
HOMEPAGE="https://github.com/flatcar/coreos-cloudinit"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
IUSE="openssh"

DEPEND="!<coreos-base/coreos-init-0.0.1-r69"
RDEPEND="
	>=sys-apps/shadow-4.1.5.1
"

src_prepare() {
	coreos-go_src_prepare

	if gcc-specs-pie; then
		CGO_LDFLAGS+=" -fno-PIC"
	fi
}

src_compile() {
	GO_LDFLAGS="-X main.version=$(git describe --dirty)" || die
	coreos-go_src_compile
}

src_install() {
	dobin ${GOBIN}/coreos-cloudinit
	udev_dorules units/*.rules
	systemd_dounit units/*.mount
	systemd_dounit units/*.path
	systemd_dounit units/*.service
	systemd_dounit units/*.target
	systemd_enable_service multi-user.target system-config.target
	systemd_enable_service multi-user.target user-config.target

  # Flatcar NANO HACK ALERT
  if ! use openssh; then
    einfo "openssh USE flag not set, creating dummy 'update-ssh-keys' script that always succeeds."
    echo -e '#!/usr/bin/true' > "${D}/usr/bin/update-ssh-keys" 
    chmod 755 "${D}/usr/bin/update-ssh-keys" 
  fi
}
