# Copyright 2015 CoreOS, Inc.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="flatcar/shim"
CROS_WORKON_REPO="https://github.com"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	CROS_WORKON_COMMIT="7ba7440c49d32f911fb9e1c213307947a777085d"
	KEYWORDS="amd64 arm64"
fi

inherit cros-workon multilib

DESCRIPTION="UEFI Shim loader"
HOMEPAGE="https://github.com/rhboot/shim"

LICENSE="BSD"
SLOT="0"
IUSE=""

RDEPEND=""
# TODO: Would be ideal to depend on sys-boot/gnu-efi package, but
# currently the shim insists on using the bundled copy. This will need
# to be addressed by patching this check out after making sure that
# our copy of gnu-efi is as usable as the bundled one.
DEPEND="
  dev-libs/openssl
  coreos-base/coreos-sb-keys
"

src_unpack() {
	cros-workon_src_unpack
	default_src_unpack
}

src_compile() {
	local emake_args=(
		CROSS_COMPILE="${CHOST}-"
	)
	# Apparently our environment already has the ARCH variable in
	# it, and Makefile picks it up instead of figuring it out
	# itself with the compiler -dumpmachine flag. But also it
	# expects a different format of the values. It wants x86_64
	# instead of amd64, and aarch64 instead of arm64.
	insinto /usr/share/sb_keys
	newins "${FILESDIR}/shim.der" shim.der
	if use amd64; then
		emake_args+=( ARCH=x86_64 )
	elif use arm64; then
		emake_args+=( ARCH=aarch64 )
	fi
  emake_args+=( ENABLE_SBSIGN=1 )
  emake_args+=( VENDOR_CERT_FILE="${SYSROOT}/usr/share/sb_keys/DB.der" )
	emake "${emake_args[@]}" || die
}

src_install() {
	local suffix
	suffix=''
	if use amd64; then
		suffix=x64
	elif use arm64; then
		suffix=aa64
	fi
	insinto /usr/lib/shim
	newins "shim${suffix}.efi" 'shim.efi'
  newins "mm${suffix}.efi" "mm${suffix}.efi"
  newins "fb${suffix}.efi" "fb${suffix}.efi"
}
