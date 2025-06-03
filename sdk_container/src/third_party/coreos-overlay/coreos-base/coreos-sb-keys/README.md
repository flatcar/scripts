## Keys & Certificates

### X.509 signature database - DB.key, DB.pem

The signature database is used by the UEFI firmware to validate signed EFI binaries (e.g. the shim). In this case, `DB.key` and `DB.pem` are only used for testing with QEMU. Real deployments use the database provided by the bare metal host or hypervisor.

### X.509 shim vendor certificates - shim.key, shim-*.pem

Unofficial builds: `shim-*.pem` are the current and historical self-signed signing certificates used to sign the bootloader and kernel. `shim.key` is the private key for the current certificate.

Official builds: `shim-*.pem` are the current and historical CA certificates that issue the signing certificates. The private key is only needed to issue new signing certificates so is kept offline.

### X.509 signing certificate - signing.pem

Unofficial builds: The current signing certificate is also the current shim vendor certificate above, so there is no separate `signing.pem`.

Official builds: `signing.pem` is the current signing certificate used to sign the bootloader and kernel. It is copied from Azure Key Vault, where the private key is also stored.

### GPG signing keys - signing*.gpg

Unofficial builds: `signing.gpg` is the current private key used to sign the kernel load script. `signing-*.gpg` are the historical public keys used to verify them. They have no expiry date.

Official builds: `signing.gpg` is the current public key used to sign the kernel load script. `signing-*.gpg` are the historical public keys used to verify them. These keys are created from their respective X.509 signing certificates. As such, the private keys are only stored in Azure Key Vault. The start and end dates of the keys also match the certificates.

## Generation of Keys & Certificates

Unofficial builds: Delete any of `DB.key`, `shim.key`, or `signing.gpg` to force recreation.

Official builds: Delete `signing.gpg` to force recreation. `shim-*.pem` must be updated manually. `signing.pem` is refreshed from Azure Key Vault using the details stored in `build_library/sbsign_util.sh`. Ensure [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) is in your `PATH`.

Run the `refresh_keys` script without any arguments. Bump the coreos-sb-keys package with the changes.
