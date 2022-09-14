# Copyright 2015 CoreOS, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="flatcar/shim"
CROS_WORKON_REPO="https://github.com"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	CROS_WORKON_COMMIT="e98d00c2eb00b1cfb25212f7527ed47d8ab3bb3a"
	KEYWORDS="amd64 arm64"
fi

inherit cros-workon multilib

DESCRIPTION="UEFI Shim loader"
HOMEPAGE="https://github.com/rhinstaller/shim"

LICENSE="BSD"
SLOT="0"
IUSE=""

RDEPEND=""
DEPEND="sys-boot/gnu-efi dev-libs/openssl"

src_unpack() {
	cros-workon_src_unpack
	default_src_unpack
}

src_compile() {
	emake \
		CROSS_COMPILE="${CHOST}-" \
		EFI_INCLUDE="${SYSROOT%/}"/usr/include/efi \
		EFI_PATH="${SYSROOT%/}"/usr/$(get_libdir) \
		shim.efi || die
}

src_install() {
	insinto /usr/lib/shim
	doins "shim.efi"
}
