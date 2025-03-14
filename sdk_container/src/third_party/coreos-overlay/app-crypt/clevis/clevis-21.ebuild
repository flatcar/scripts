# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

DESCRIPTION="Automated Encryption Framework"
HOMEPAGE="https://github.com/latchset/clevis"
SRC_URI="https://github.com/latchset/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+luks +tpm"

DEPEND="
	dev-libs/jose
	sys-fs/cryptsetup
	sys-kernel/dracut
	luks? (
		app-misc/jq
		dev-libs/luksmeta
	)
	tpm? ( app-crypt/tpm2-tools )
"
# Flatcar: The Clevis meson build will not build certain features if certain executables are not found at build time, such as `tpm2_createprimary`.
# The meson function `find_program` that checks for the existence of the executables does not seem to search paths under ${ROOT}, but rather
# under `/`. A fix to make meson find all binaries and include all desired features is to install such runtime dependencies into the SDK.
BDEPEND="
	luks? (
		app-misc/jq
		dev-libs/luksmeta
	)
	tpm? ( app-crypt/tpm2-tools )
"
RDEPEND="
	${DEPEND}
	dev-libs/jansson
	dev-libs/openssl:=
"

PATCHES=(
	# Fix for systemd on Gentoo
	"${FILESDIR}/clevis-meson.patch"
	# Flatcar:
	# * install `clevis-pin-tang` dracut module in the absence of dracut `network`
	#   module; Flatcar uses a custom network module
	# * skip copying `/etc/services` into initramfs when installing `clevis` dracut
	# 	module, which would fail
	"${FILESDIR}/clevis-dracut-flatcar.patch"
)
