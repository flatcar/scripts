#!/bin/bash
set -euo pipefail
# note: to make sure you forward the whole env, you can first run 'source <(export)' before starting this script

# Add /opt/bin explicitly because the lbzcat binary is there on the Jenkins workers
export PATH="$PATH:/opt/bin"

# Use a system session unit because the user session may not be set up correctly in a CI env
ARGS=("--system" "--collect" "--same-dir" "--pipe" "--wait" "--property=User=$USER" "--property=Group=$USER")
# Extra "sh -c" is needed to only export the exported variables
for VARNAME in $(sh -c 'compgen -v'); do
  set +u
  VAL="${!VARNAME}"
  set -u
  ARGS+=("--setenv" "${VARNAME}=${VAL}")
done

UNITNAME="run-$(date '+%s')-${RANDOM}"

# The --pipe option does not stop the unit when the systemd-run process is killed, we have to do this through a trap
# (and --pty as alternative doesn't behave well because it leads to processes expecting stdin when there is none)
function cancel() {
  echo
  echo "Terminating"
  sudo systemctl stop "${UNITNAME}"
  exit 1
}
trap cancel INT

ARGS+=("--unit=${UNITNAME}")

sudo systemd-run "${ARGS[@]}" "$@"
