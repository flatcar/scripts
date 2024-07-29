# Copyright (c) 2024 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

if [[ ${COREOS_OFFICIAL:-0} -ne 1 ]]; then
    SBSIGN_KEY="/usr/share/sb_keys/unofficial/shim.key"
    SBSIGN_CERT="/usr/share/sb_keys/unofficial/shim.pem"
    SBSIGN_GPG="/usr/share/sb_keys/unofficial/signing.gpg"
else
    SBSIGN_KEY="pkcs11:token=flatcar-sb-dev-hsm-sign-2025"
    SBSIGN_CERT="/usr/share/sb_keys/official/signing.pem"
    SBSIGN_GPG="/usr/share/sb_keys/official/signing.gpg"
fi

PKCS11_MODULE_PATH="$(pkg-config p11-kit-1 --variable p11_module_path)/azure-keyvault-pkcs11.so"

PKCS11_ENV=(
    AZURE_CORE_COLLECT_TELEMETRY=no
    AZURE_KEYVAULT_URL="https://flatcar-sb-dev-kv.vault.azure.net/"
    PKCS11_MODULE_PATH="${PKCS11_MODULE_PATH}"
    AZURE_KEYVAULT_PKCS11_DEBUG=1
)

do_sbsign() {
    info "Signing ${@:$#} with ${SBSIGN_KEY}"

    if [[ ${SBSIGN_KEY} == pkcs11:* ]]; then
        set -- --engine pkcs11 "${@}"
    fi

    # Needs Key Vault Crypto User role.
    sudo env "${PKCS11_ENV[@]}" sbsign \
        --key "${SBSIGN_KEY}" \
        --cert "${SBSIGN_CERT}" \
        "${@}"
}

do_smime() {
    if [[ ${SBSIGN_KEY} == pkcs11:* ]]; then
        set -- --engine pkcs11 -keyform engine "${@}"
    fi

    env "${PKCS11_ENV[@]}" openssl smime \
        -inkey "${SBSIGN_KEY}" \
        -signer "${SBSIGN_CERT}" \
        "${@}"
}

setup_gnupghome() {
    export GNUPGHOME
    GNUPGHOME=$(mktemp -d)
    trap 'gpgconf --kill gpg-agent; rm -r -- "${GNUPGHOME}"' EXIT

    # Unofficial builds simply use a local private key.
    [[ ${COREOS_OFFICIAL:-0} -ne 1 ]] && return

    cat <<EOF > "${GNUPGHOME}"/gpg-agent.conf
scdaemon-program $(type -P gnupg-pkcs11-scd)
EOF

    cat <<EOF > "${GNUPGHOME}"/gnupg-pkcs11-scd.conf
providers kms
provider-kms-library ${PKCS11_MODULE_PATH}
log-file /dev/null
EOF

    # This fetches the private keys from AKV.
    gpg --card-status
}

do_gpg() {
    (
        export "${PKCS11_ENV[@]}"
        setup_gnupghome
        gpg --import "${SBSIGN_GPG}"
        gpg "${@}"
    )
}
