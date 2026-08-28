# SELinux Container Domain Reference

Azure Container Linux (ACL) enables SELinux in enforcing mode by default.
Operators can configure a node to use permissive mode for troubleshooting;
use `getenforce` to verify its current mode. Container workloads run in
SELinux process domains that limit their access to the host and to other
containers.

This guide documents the container workload domains shipped by ACL and helps
operators choose the narrowest domain that meets a workload's requirements.
It does not list every host service domain in the complete SELinux policy.

## Choosing a workload domain

Use `container_t` by default. Select another domain only when the workload has
a requirement described in this guide.

| Requirement | Domain |
| --- | --- |
| General container workload | `container_t` |
| Read host logs without broad host privileges | `container_logreader_t` |
| Run a containerized KVM workload | `container_kvm_t` |
| Broadly privileged system container | `spc_t` |
| Broadly privileged rootless or user container | `spc_user_t` |

Do not select `spc_t` merely to make SELinux AVC denials disappear. Determine
which host resource the workload needs and use a specialized domain or request
a narrowly scoped policy extension.

## Supported workload domains

The compiled ACL `selinux-policy-2.20250213-10` container policy contains five
workload process domains:

| Domain | Policy engine scope | MCS constrained | Intended use |
| --- | --- | --- | --- |
| `container_t` | System and user engines | ✅ Yes | Default confined container |
| `container_logreader_t` | System and user engines | ✅ Yes | Confined host-log collector |
| `container_kvm_t` | System engines | ✅ Yes | Containerized KVM workload |
| `spc_t` | System engines | ❌ No | Privileged system container |
| `spc_user_t` | User engines | ❌ No | Privileged rootless or user container |

In policy scope, a system engine is a rootful container engine running as a
system service, while a user engine is a rootless engine running in a user's
session. This classification does not mean ACL ships or supports every engine
represented in the policy. Runtime support, admission policy, Linux
capabilities, device assignment, and discretionary file permissions still
apply.

### `container_t`

`container_t` is the default and should be used for most workloads. It has the
common permissions needed to execute and manage files labeled for its
container, use container networking, and access routine namespaced kernel
interfaces.

`container_t`:

- Is constrained by the runtime-assigned MCS categories.
- Does not receive general access to host files merely because they are bind
  mounted.
- Does not receive the specialized host-log, KVM, or privileged-container
  permissions described below.

`svirt_lxc_net_t` is a compatibility alias for `container_t`; use the canonical
`container_t` name in new configurations.

### `container_logreader_t`

`container_logreader_t` extends the normal confined container policy with
read, directory traversal, and symlink access to types carrying the `logfile`
attribute. It is intended for node-level log agents that would otherwise be
run as broadly privileged containers.

It additionally receives read-only mmap access to persistent files labeled
`systemd_journal_t`, which is required by tools such as `journalctl --file`.
Inotify watch access applies only to `container_log_t`, not to every host log
type.

The domain intentionally does not grant:

- Write, append, create, delete, rename, or relabel access to host logs.
- Blanket access to arbitrary host files beyond the common `container_domain`
  policy it shares with `container_t`.
- The broad host privileges provided by `spc_t`.

Common container policy permits limited reads of some non-log host types, such
as executable and configuration content. Mount only the paths the collector
requires; do not treat the process domain as a mount boundary.

Like Fedora, RHEL, and other distributions using `container-selinux`, ACL
allows this domain to read auditd-managed files labeled `auditd_log_t`.
Audit logs contain host-wide authentication, syscall, and AVC data; mount
`/var/log/audit` only when the collector requires that information.

Audit files are readable sequentially but are not memory-mappable. The policy
denies `map` on `auditd_log_t` and suppresses that denial, so an mmap-based
reader fails without producing an AVC. Configure audit-file collectors to use
sequential I/O.

ACL stores the systemd journal persistently under `/var/log/journal`. The
journal uses `systemd_journal_t` and can contain kernel audit and AVC records,
so it remains readable when mounted into the collector. Restrict mounted paths
when a collector should not receive audit data.

The host log path must still be mounted into the container. Make the mount
read-only as defense in depth, and do not relabel the host log directory.

### `container_kvm_t`

`container_kvm_t` is the confined domain for containerized virtualization
workloads such as KubeVirt. It shares the common `container_domain` policy with
`container_t` but is a sibling domain, not a superset. Its domain-specific
rules add `net_admin` and `sys_resource`, tun socket relabeling, selected
sysfs, cgroup, and sysctl reads, and inherited FD, FIFO, and tun interactions
with `spc_t`.

The domain remains MCS constrained. It does not directly grant access to
objects labeled `kvm_device_t`, `vhost_device_t`, or `vfio_device_t`. Actual
device access requires an inherited descriptor, an appropriate device label,
or separately reviewed policy in addition to runtime device and capability
configuration.

Do not use `container_kvm_t` for non-virtualization workloads.

### `spc_t`

`spc_t` is the super-privileged domain for system containers. Container
runtimes commonly select it for privileged workloads.

Compared with the confined domains, `spc_t`:

- Is not an `mcs_constrained_type`.
- Receives broad capabilities and host-resource permissions.
- Can load kernel modules, administer container storage and runtime state, and
  perform other host-management operations allowed by policy.
- Is SELinux-unconfined on stock ACL because the unconfined policy module is
  loaded.

Runtime controls, Linux capabilities, namespaces, and discretionary access
control can still deny an operation. Nevertheless, `spc_t` should be treated
as broad host access, not as a convenient general-purpose domain. A system
that explicitly disables the unconfined module removes the unconfined
attribute set but still leaves `spc_t` with broad privileged-container policy.

### `spc_user_t`

`spc_user_t` is the privileged counterpart used by user or rootless container
engines. It belongs to the privileged-container policy class but not the
system-container class.

Like `spc_t`, it is not MCS constrained and is SELinux-unconfined on stock ACL.
Disabling the unconfined module removes those unconfined attributes, but the
domain remains a broad privileged-container type. Rootless user-namespace and
kernel restrictions still apply; this domain is not a substitute for a
purpose-built confined domain.

## Capability comparison

This table summarizes SELinux policy intent, not every individual permission.

| Capability | `container_t` | `container_logreader_t` | `container_kvm_t` | `spc_t` / `spc_user_t` |
| --- | --- | --- | --- | --- |
| Common container execution and storage | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Runtime-assigned MCS isolation | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No |
| Read types carrying `logfile` | ❌ No | ✅ Yes | ❌ No | ⚠️ Unconfined on stock ACL |
| Read and map persistent systemd journals | ❌ No | ✅ Yes | ❌ No | ⚠️ Unconfined on stock ACL |
| Read auditd-managed `auditd_log_t` files | ❌ No | ✅ Yes | ❌ No | ⚠️ Unconfined on stock ACL |
| KVM-specific policy | ❌ No | ❌ No | ✅ Yes | ❌ No — broad privileged access instead |
| Privileged-container policy class | ❌ No | ❌ No | ❌ No | ✅ Yes |
| SELinux-unconfined on stock ACL | ❌ No | ❌ No | ❌ No | ✅ Yes |

## Selecting a domain

### Kubernetes

For a single-container pod, set only the required process type and allow the
runtime to allocate the MCS level:

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
        # Journal files require host DAC access. See the non-root guidance below.
        runAsUser: 0
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

Kubernetes type selection requires the container runtime's CRI SELinux support
to be enabled. ACL's embedded containerd configuration sets
`enable_selinux = true`. Do not assume the same default on other node OS
images; verify the effective setting on any node with:

```bash
crictl --runtime-endpoint unix:///run/containerd/containerd.sock info \
  | jq -r '.config.enableSelinux'
```

Cluster admission policy must allow the selected type. Do not set
`privileged: true` unless the workload genuinely requires the privileged
domain and associated runtime access. For `container_logreader_t`, add a
separate read-only `/var/log/audit` mount only when the collector must read
auditd-managed files. Stock ACL does not run auditd, so this mount is needed
only on customized hosts that add it.

When SELinux options omit an explicit level, containerd allocates a new MCS
level for that container instead of inheriting the sandbox label. In a
multi-container pod, independent type-only overrides can therefore prevent
containers from sharing MCS-constrained IPC, sockets, processes, or relabeled
volumes.

Kubernetes has no built-in field that both generates a unique per-pod level
and overrides the type. ACL does not ship an allocator for this case, so use a
single-container pod for `container_logreader_t` and run other workloads in
separate pods.

An advanced multi-container deployment requires a mutating admission webhook
that assigns the same level to the sandbox and every participating container.
Its allocator must be coordinated with containerd on every node, such as by
using a disjoint reserved category range, so it cannot select a level already
assigned to another container. Do not reuse one static level across pods;
doing so collapses MCS isolation between them.

## MCS isolation

`container_t`, `container_logreader_t`, and `container_kvm_t` remain
`mcs_constrained_type` members. The container runtime assigns categories such
as `s0:c123,c456` so similarly typed containers cannot access each other's
objects.

ACL builds the targeted policy in MCS mode. Standard host log file contexts
resolve to level `s0`, which is dominated by a normally categorized container
process. The log-reader domain can therefore use its type-enforcement read
permissions without receiving an all-category level.

Do not set `seLinuxOptions.level` to `s0:c0.c1023` and do not remove the
runtime-assigned categories. Either action weakens isolation from other
containers.

## Names that are not workload domains

Not every SELinux name containing `container` or ending in `_t` is a process
domain that should be selected for a workload.

### Engine and helper process domains

These domains are assigned to container infrastructure and should not be set
in a pod or container security context:

| Domain | Purpose |
| --- | --- |
| `container_engine_t` | Generic container engine |
| `dockerd_t`, `dockerd_user_t` | Docker daemon |
| `dockerc_t`, `dockerc_user_t` | Docker client |
| `crio_t` | CRI-O daemon |
| `crio_conmon_t` | CRI-O container monitor |
| `podman_t`, `podman_user_t` | Podman system and user engines |
| `podman_conmon_t`, `podman_user_conmon_t` | Podman container monitors |

Some infrastructure domains are included for policy compatibility even when
ACL does not ship or support the corresponding runtime. Their presence in the
compiled policy is not a product support statement.

The shipped container runtime contexts file also contains an
`init_process` entry naming `container_init_t`. The compiled
`selinux-policy-2.20250213-10` ACL policy does not define that type, so it is
not an available workload domain and must not be selected.

### File and object types

Types such as `container_file_t`, `container_ro_file_t`, `container_log_t`,
`container_runtime_t`, `container_var_lib_t`, and `container_device_t` label
files or objects. They are not process domains.

Names such as `container_domain`, `container_system_domain`,
`container_user_domain`, and `privileged_container_domain` are policy
attributes grouping multiple types. They are also not selectable process
domains.

## Requesting narrower policy

If none of the available domains is narrow enough for a workload:

1. Start from `container_t`, not `spc_t`.
2. Identify the exact host paths, SELinux object types, devices, capabilities,
   and operations the workload requires.
3. Mount only required paths and use read-only mounts where possible.
4. Capture the relevant AVC denials from an enforcing test system.
5. Request a dedicated domain or narrowly scoped policy interface.
6. Test both the required access and explicit denials for unrelated host
   resources.

A specialized domain should describe a stable workload role, as
`container_logreader_t` and `container_kvm_t` do, rather than accumulate
permissions for one deployment.

## Validation

Confirm the selected process context from inside the container:

```bash
cat /proc/self/attr/current
```

For `container_logreader_t`, confirm the journal mount and read the persistent
journal:

```bash
grep ' /host/var/log/journal ' /proc/self/mountinfo
journalctl --file='/host/var/log/journal/*/system.journal' -n 5
```

The context should report `container_logreader_t`, and the journal read should
succeed when the collector image includes `journalctl` and the process passes
discretionary access control on the journal files. ACL journal files are
`root:systemd-journal` mode `0640`, so the example runs the collector as root.
For a non-root collector, get the journal file's effective group ID on the
node:

```bash
stat -c '%g' /var/log/journal/*/system.journal | head -n 1
```

Add that value to the pod's `securityContext.supplementalGroups`. Do not assume
a fixed group ID across images. If a read fails with `EACCES` while the host
shows no related AVC, the cause is DAC rather than SELinux. A write attempt to
a host log should fail.

Stock ACL creates `/var/log/audit` but does not run auditd, so the directory is
normally empty. Hosts that add auditd should treat access to its files as
sensitive and mount them only when needed.

On the host, check recent SELinux denials with:

```bash
journalctl -g 'avc:  denied' --since -10min
```

Some policy denials are suppressed by `dontaudit` rules and do not appear in
the journal. On a development image that retains a writable SELinux module
store, temporarily expose suppressed denials while reproducing the issue:

```bash
sudo semodule -DB
# Reproduce the failure and inspect the journal.
sudo journalctl -g 'avc:  denied' --since -10min
sudo semodule -B
```

Always restore `dontaudit` rules after troubleshooting. If `semodule -DB`
reports that the module store is unavailable, as on current minimized ACL
images, reproduce the issue on an unminimized development image.

Inspect host labels when troubleshooting:

```bash
ls -ldZ /var/log
find /var/log -maxdepth 2 -type f -exec ls -lZ -- {} +
```
