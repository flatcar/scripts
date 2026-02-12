# Copyright 2015 CoreOS, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="UEFI Shim loader"
HOMEPAGE="https://github.com/rhboot/shim"
SRC_URI="https://github.com/rhboot/shim/releases/download/${PV}/shim-${PV}.tar.bz2"
KEYWORDS="amd64 arm64"

LICENSE="BSD"
SLOT="0"
IUSE="official"

# TODO: Would be ideal to depend on sys-boot/gnu-efi package, but
# currently the shim insists on using the bundled copy. This will need
# to be addressed by patching this check out after making sure that
# our copy of gnu-efi is as usable as the bundled one.
DEPEND="
	dev-libs/openssl
"
BDEPEND="
	coreos-base/coreos-sb-keys
"

PATCHES=(
	"${FILESDIR}/0001-Fix-parallel-build-of-gnu-efi.patch"
)

src_compile() {
	use official && [[ -z ${SHIM_SIGNING_CERTIFICATE} ]] &&
		die "USE=official but SHIM_SIGNING_CERTIFICATE environment variable is unset"

	sed -e "s/@@VERSION@@/${PVR}/" "${FILESDIR}"/sbat.csv.in >"${WORKDIR}/sbat.csv" || die

	unset ARCH
	emake \
		CROSS_COMPILE="${CHOST}-" \
		ENABLE_SBSIGN=1 \
		SBATPATH="${WORKDIR}"/sbat.csv \
		VENDOR_CERT_FILE=$(usex official "${SHIM_SIGNING_CERTIFICATE}" "${BROOT}"/usr/share/sb_keys/shim.der)
}

src_install() {
	insinto /usr/lib/shim
	doins shim?*.efi mm?*.efi
}
