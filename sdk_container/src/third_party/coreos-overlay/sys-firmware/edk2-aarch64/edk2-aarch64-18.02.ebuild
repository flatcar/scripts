# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Linaro edk2 ARM64 EFI firmware"
HOMEPAGE="https://github.com/tianocore/edk2"
SRC_URI="http://releases.linaro.org/reference-platform/enterprise/firmware/18.02/release/qemu-aarch64/QEMU_EFI.fd"

LICENSE="BSD-2-Clause-Patent"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"

src_unpack() {
	mkdir "${S}"
	cp ../distdir/"${A}" "${S}"/QEMU_EFI.fd
}

src_install() {
	mkdir -p "${D}/usr/share/edk2-aarch64"
	cp QEMU_EFI.fd "${D}/usr/share/edk2-aarch64/QEMU_EFI.fd"
}
