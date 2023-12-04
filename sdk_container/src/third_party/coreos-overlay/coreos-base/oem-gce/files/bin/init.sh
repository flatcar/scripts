#!/bin/bash -ex
# GCE can work with our normal file system, but it needs an "init system".
# Here is a better place to install this script so it doesn't get put in real
# images built from the GCE Python package.

# Write a configuration template if it does not exist.
[ -e /etc/default/instance_configs.cfg.template ] ||
echo -e > /etc/default/instance_configs.cfg.template \
    '[InstanceSetup]\nset_host_keys = false'

# Run the initialization scripts.
/usr/bin/google_instance_setup
/usr/bin/google_metadata_script_runner --script-type startup

# Handle the signal to shut down this service.
trap 'stopping=1 ; kill "${daemon_pids[@]}" || :' SIGTERM

# Fork the daemon processes.
daemon_pids=()
for d in accounts clock_skew network
do
        /usr/bin/google_${d}_daemon & daemon_pids+=($!)
done

# Notify the host that everything is running.
NOTIFY_SOCKET=/run/systemd/notify /usr/bin/systemd-notify --ready

# Pause while the daemons are running, and stop them all when one dies.
wait -n "${daemon_pids[@]}" || :
kill "${daemon_pids[@]}" || :

# If a daemon died while we're not shutting down, fail.
test -n "$stopping" || exit 1

# Otherwise, run the shutdown script before quitting.
exec /usr/bin/google_metadata_script_runner --script-type shutdown
