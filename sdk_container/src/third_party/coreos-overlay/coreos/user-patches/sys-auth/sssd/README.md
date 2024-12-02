The `0000-drop-runtime-check-of-ldap-conncb.patch' patch removes a
runtime check that was checking for a broken callback code in OpenLDAP
before 2.4.13. This version was released ages ago (2008), so the check
is not really useful anymore and it is a hindrance when we want to
cross-compile the code and have the callbacks used.

The `0001-enable-nss-lookups.patch` enabled nss lookup with sss
plugin, even if sssd is not running. This is not really upstreamable,
maybe a USE flag would be better for it.
