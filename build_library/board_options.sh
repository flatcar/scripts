# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

if [ -z "${FLAGS_board}" ]; then
  error "--board is required."
  exit 1
fi

BOARD="${FLAGS_board}"
BOARD_ROOT="/build/${BOARD}"
ARCH=$(get_board_arch ${BOARD})

# What cross-build are we targeting?
. "${BOARD_ROOT}/etc/portage/make.conf" || die

# check if any of the given use flags are enabled for a pkg
pkg_use_enabled() {
  local pkg="${1}"; shift

  # for every flag argument, turn it into a regexp that matches it as
  # either '+${flag}' or '(+${flag})'
  local -a grep_args=()
  local flag
  for flag; do
      grep_args+=( -e '^(\?+'"${flag}"')\?$' )
  done
  local -i rv=0

  equery-"${BOARD}" --quiet uses --forced-masked "${pkg}" | grep --quiet "${grep_args[@]}" || rv=$?
  return ${rv}
}

# Usage: pkg_version [installed|binary|ebuild] some-pkg/name
# Prints: some-pkg/name-1.2.3
# Note: returns 0 even if the package was not found.
pkg_version() {
  portageq-"${BOARD}" best_visible "${BOARD_ROOT}" "$1" "$2" || :
}

# Usage: pkg_provides [installed|binary] some-pkg/name-1.2.3
# Prints: x86_32: libfoo.so.2 x86_64: libfoo.so.2
pkg_provides() {
  local provides p
  provides=$(portageq-"${BOARD}" metadata "${BOARD_ROOT}" "$1" "$2" PROVIDES)

  if [[ -z "$provides" ]]; then
    return
  fi

  # convert:
  #  x86_32: libcom_err.so.2 libss.so.2 x86_64: libcom_err.so.2 libss.so.2
  # into:
  #  x86_32 libcom_err.so.2 libss.so.2
  #  x86_64 libcom_err.so.2 libss.so.2
  echo -n "# $1:"
  for p in ${provides}; do
    if [[ "$p" == *: ]]; then
      echo
      echo -n "${p%:}"
    else
      echo -n " $p"
    fi
  done
  echo
}
