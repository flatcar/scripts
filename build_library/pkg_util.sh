# Copyright (c) 2025 The Flatcar Maintainers. All rights reserved.
# Use of this source code is governed by the Apache 2.0 license.

# check if any of the given use flags are enabled for a pkg
pkg_use_enabled() {
  local board=${1}; shift
  local pkg=${1}; shift

  # for every flag argument, turn it into a regexp that matches it as
  # either '+${flag}' or '(+${flag})'
  local -a grep_args=()
  local flag
  for flag; do
    grep_args+=( -e '^(\?+'"${flag}"')\?$' )
  done
  local -i rv=0
  local equery='equery'
  if [[ -n ${board} ]]; then
    equery+="-${board}"
  fi

  "${equery}" --quiet uses --forced-masked "${pkg}" | grep --quiet "${grep_args[@]}" || rv=$?
  return ${rv}
}

is_selinux_enabled() {
  local board=${1}; shift

  pkg_use_enabled "${board}" coreos-base/coreos selinux
}
