# SELinux Container Domains

Azure Container Linux (ACL) enables SELinux in enforcing mode by default.
Operators can configure a node to use permissive mode for troubleshooting;
use `getenforce` to verify its current mode. Container workloads use SELinux
domains to limit their access to the host and to other containers. The
container runtime selects a domain and allocates an MCS category set for each
workload.

## Workload domains

| Domain | Intended use | Host access |
| --- | --- | --- |
| `container_t` | Default container workload | No general access to host logs or host files |
| `container_logreader_t` | Opt-in log collector | Read-only access to objects labeled with an SELinux log type |
| `container_kvm_t` | Containerized KVM workload | KVM-specific device and process access |
| `spc_t` | Privileged container | Broad host access; may be unconfined when the unconfined policy module is enabled |

`container_engine_t` is reserved for the container engine itself and is not a
workload domain.

Use `container_t` unless the workload requires a documented specialized
domain. Do not use `spc_t` solely to collect logs.

## Confined log collectors

`container_logreader_t` extends the normal confined container policy with
read, directory traversal, and symlink access to types carrying the `logfile`
attribute. Inotify watch access applies only to `container_log_t`, not to other
host log types. Access is based on the SELinux label, not the path. Inspect
host labels with:

```bash
ls -ldZ /var/log
find /var/log -maxdepth 2 -type f -exec ls -lZ -- {} +
```

The domain intentionally does not grant:

- Write, append, create, delete, rename, or relabel access to host logs.
- Blanket access to arbitrary host files beyond the common `container_domain`
  policy it shares with `container_t`.
- The broad host privileges provided by `spc_t`.

Like Fedora, RHEL, and other distributions using `container-selinux`, ACL
allows this domain to read auditd-managed files labeled `auditd_log_t`.
Audit logs contain host-wide authentication, syscall, and AVC data; mount
`/var/log/audit` only when the collector requires that information.

ACL stores the systemd journal persistently under `/var/log/journal`. The
journal uses `systemd_journal_t` and can contain kernel audit and AVC records,
so it remains readable when mounted into the collector. Restrict mounted paths
when a collector should not receive audit data.

The host log path must still be mounted into the container. Make the mount
read-only as defense in depth, and do not relabel the host log directory.

### Kubernetes example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: host-log-reader
spec:
  containers:
    - name: collector
      image: <collector-image>
      securityContext:
        seLinuxOptions:
          type: container_logreader_t
      volumeMounts:
        - name: host-journal
          mountPath: /host/var/log/journal
          readOnly: true
  volumes:
    - name: host-journal
      hostPath:
        path: /var/log/journal
        type: Directory
```

Cluster admission policy must allow the `container_logreader_t` type. Do not
set the pod to `privileged: true`. Add a separate read-only
`/var/log/audit` mount only when the collector must read auditd-managed files.

### Podman example

```bash
podman run --rm \
  --security-opt label=type:container_logreader_t \
  --volume /var/log/journal:/host/var/log/journal:ro \
  <collector-image>
```

Do not add `:z` or `:Z` to the volume. Those options relabel host content and
can interfere with host logging services. Add a separate
`/var/log/audit:/host/var/log/audit:ro` mount only when auditd files are
required.

## MCS isolation

`container_logreader_t` remains an `mcs_constrained_type` and retains normal
container MCS isolation. ACL builds the targeted policy in MCS mode, where
standard host log file contexts resolve to level `s0`. A container at its
runtime-assigned level, such as `s0:c123,c456`, dominates `s0` and can use the
domain's read permissions without receiving an all-category level.

Do not set `seLinuxOptions.level` to `s0:c0.c1023` and do not remove the
runtime-assigned categories. Either action weakens isolation from other
containers.

## Validation

Confirm the selected process domain and mounted labels from the container:

```bash
cat /proc/self/attr/current
ls -ldZ /host/var/log/journal
journalctl --file='/host/var/log/journal/*/system.journal' -n 5
```

The process context should report `container_logreader_t`, and the journal
read should succeed when the collector image includes `journalctl`. A write
attempt to a host log should fail. Stock ACL creates `/var/log/audit` but does
not run auditd, so the directory is normally empty. Hosts that add auditd
should treat access to its files as sensitive and mount them only when needed.
On the host, check unexpected SELinux denials with:

```bash
journalctl -g 'avc:  denied' --since -10min
```
