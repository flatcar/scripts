## Keys & Certificates

- PK (Platform Key): The Platform Key is the key to the platform.
- KEK (Key Exchange Key): The Key Exchange Key is used to update the signature database.
- DB (Signature Database): The signature database is used to validate signed EFI binaries.
- Shim Certificates: Our set of certificates


## Generation of Keys & Certificates


Generate the our shim certificates:

```
openssl genrsa -out "shim.key" 2048
openssl req -new -x509 -sha256 -subj "/CN=shim/" -key "shim.key" -out "shim.pem" -days 7300
openssl x509 -in "shim.pem" -inform PEM -out "shim.der" -outform DER
```
