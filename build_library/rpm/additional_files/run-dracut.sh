#!/bin/bash
export PATH="/usr/bin:/usr/sbin:/bin:/sbin:/usr/lib/systemd"
export DRACUT_NO_XATTR=1
# Ensure ldconfig has been run
ldconfig 2>/dev/null || true
# Run dracut with the provided arguments
exec /usr/bin/dracut "$@"
