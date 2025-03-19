# Copyright (c) 2024 The Flatcar Maintainers.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

if [[ ${COREOS_OFFICIAL:-0} -ne 1 ]]; then
    SBSIGN_KEY="/usr/share/sb_keys/shim.key"
    SBSIGN_CERT="/usr/share/sb_keys/shim.pem"
else
    SBSIGN_KEY="pkcs11:token=flatcar-sb-dev-signing-hsm"
    unset SBSIGN_CERT
fi

PKCS11_MODULE_PATH="/usr/$(get_sdk_libdir)/pkcs11/azure-keyvault-pkcs11.so"

PKCS11_ENV=(
    AZURE_KEYVAULT_URL="https://flatcar-sb-dev-kv.vault.azure.net/"
    PKCS11_MODULE_PATH="${PKCS11_MODULE_PATH}"
    AZURE_KEYVAULT_PKCS11_DEBUG=1
)

get_sbsign_cert() {
    if [[ ${SBSIGN_KEY} != pkcs11:* || -s ${SBSIGN_CERT-} ]]; then
        return
    fi

    SBSIGN_CERT=$(mktemp -t signing-cert.XXXXXXXXXX.pem)
    info "Fetching ${SBSIGN_KEY} from Azure"

    # Needs Key Vault Reader role.
    env "${PKCS11_ENV[@]}" p11-kit export-object \
        --provider "${PKCS11_MODULE_PATH}" \
        "${SBSIGN_KEY};type=cert" \
        | tee "${SBSIGN_CERT}"
}

cleanup_sbsign_certs() {
    if [[ ${SBSIGN_CERT-} == "${TMPDIR-/tmp}"/* ]]; then
        rm -f -- "${SBSIGN_CERT}"
    fi
}

do_sbsign() {
    get_sbsign_cert
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
