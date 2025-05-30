# Copyright (c) 2015 CoreOS Inc.
# Copyright (c) 2024 The Flatcar Maintainers.
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Flatcar Secure Boot keys"
HOMEPAGE="https://www.flatcar.org/"
S="${WORKDIR}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm64"

BDEPEND="
	app-emulation/virt-firmware
	dev-libs/openssl
"

# Arbitrary value created for Flatcar.
OWNER_GUID="4a974879-bf65-4eb8-b404-ac3a6141121e"

src_compile() {
	local TYPE
	for TYPE in unofficial official; do
		mkdir "${TYPE}" || die

		# Gather all the shim vendor PEM certs into an array.
		local FILES=( "${FILESDIR}/${TYPE}"/shim-*.pem )

		# Rewrite the newest shim vendor PEM cert in a consistent PEM format,
		# checking its validity. Only the newest is needed in PEM format for
		# inserting into the kernel to verify the verity root hash at boot time.
		openssl x509 -in "${FILES[-1]}" -inform PEM -out "${TYPE}"/shim.pem || die

		local ARGS=() FILE
		for FILE in "${FILES[@]}"; do
			# Add each shim vendor PEM cert to the DER ESL creation below.
			ARGS+=( --add-cert "${OWNER_GUID}" "${FILE}" )
		done

		# This ingests shim vendor PEM certs and outputs a combined DER ESL.
		virt-fw-sigdb "${ARGS[@]}" --output "${TYPE}"/shim.esl || die
	done

	# Rewrite the official signing PEM cert in a consistent PEM format, checking
	# its validity. Only the newest is needed in PEM format to sign the
	# bootloader and the kernel image. Unofficial builds are already covered
	# above because the shim vendor cert /is/ the signing cert, not a CA.
	openssl x509 -in "${FILESDIR}"/official/signing.pem -inform PEM -out official/signing.pem || die
}

src_install() {
	insinto /usr/share/sb_keys
	newins - owner.txt <<< "${OWNER_GUID}"
	doins -r unofficial official

	insinto /usr/share/sb_keys/unofficial
	doins "${FILESDIR}"/unofficial/{DB.{key,pem},shim.key}
}
