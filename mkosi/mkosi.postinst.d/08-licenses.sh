#!/usr/bin/env bash
. "${SRCDIR}/lib/postinst.sh"

# licenses.json covers base and the built-in sysexts, like upstream's.
"${SRCDIR}/tools/write-licenses.sh" "${builtin_sysexts[@]}"
