# Kdump on ACL

ACL ships with [kdump](https://www.kernel.org/doc/html/latest/admin-guide/kdump/kdump.html)
support built in, but it is **disabled by default**. Kdump uses `kexec` to boot
into a small *capture kernel* when the primary kernel panics, allowing a crash
dump (`vmcore`) of the failed kernel's memory to be written to disk for later
analysis.

## Enabling kdump

ACL boots via systemd-boot, which auto-discovers per-UKI addons in
`EFI/Linux/vmlinuz-<kernel_version>.efi.extra.d/` and appends their cmdline to that UKI. A kdump
addon template (`crashkernel=256M`) is pre-built on the ESP at
`acl/uki-addons/kdump.addon.efi`. To turn kdump on, copy it into the `.extra.d`
directory for the running kernel's UKI and reboot:

```bash
KVER=$(uname -r)
sudo mkdir -p "/boot/EFI/Linux/vmlinuz-${KVER}.efi.extra.d"
sudo cp /boot/acl/uki-addons/kdump.addon.efi \
        "/boot/EFI/Linux/vmlinuz-${KVER}.efi.extra.d/kdump.addon.efi"
sudo reboot
```

The ACL UKI is named after the kernel it embeds — `vmlinuz-<kernel_version>.efi`
— so the addon directory is **version-specific** and must match the kernel you
are booting (hence `uname -r` above).

To **disable** kdump again, remove the addon and reboot:

```bash
KVER=$(uname -r)
sudo rm -f "/boot/EFI/Linux/vmlinuz-${KVER}.efi.extra.d/kdump.addon.efi"
sudo reboot
```

No image rebuild is required to toggle kdump on or off.

> **Kernel updates:** because the addon directory is tied to the UKI's kernel
> version, a kernel update installs a new UKI (`vmlinuz-<new_version>.efi`) with
> its own empty `.extra.d`. Re-copy the addon into the new UKI's directory after
> updating, or kdump will silently revert to disabled.

> **Secure Boot:** the addon must be signed by a key trusted by the image's
> Secure Boot `db` or it will be rejected at boot. The template copy is signed
> during the build for runtime use (see `build_library/rpm/sign_uki_ephemeral.sh`);
> if you rebuild or modify the addon yourself, re-sign it with the appropriate
> key.

## Verifying

After rebooting with kdump enabled:

```bash
# crashkernel memory should be reserved (non-zero)
cat /sys/kernel/kexec_crash_size

# kdump.service should be active and the capture kernel loaded
systemctl status kdump.service
cat /sys/kernel/kexec_crash_loaded   # 1 == capture kernel loaded
```

To test end to end, trigger a panic on a disposable VM and confirm a `vmcore`
appears under `/var/crash/`:

```bash
echo c | sudo tee /proc/sysrq-trigger   # forces a kernel crash — VM will reboot
```

## Collecting a dump

After a crash, the `vmcore` is written to a timestamped directory under
`/var/crash/`. Copy it off the machine for analysis with `crash` or
`makedumpfile`. ACL's default `core_collector` already compresses and strips the
dump (`makedumpfile -l --message-level 7 -d 31`).

## Why kdump is off by default

Enabling kdump reserves a block of RAM (256 MB on ACL) via `crashkernel=` that
is unavailable to the running system. Production images leave it off so that
memory is available to workloads; it is turned on only when you need to capture
a crash.

## How kdump is set up in the image

Two build-time steps prepare the image (both run unconditionally on every
build):

- **`_configure_kdump_rpm`** (`build_library/rpm/build_image_util.sh`) installs
  the in-image configuration into the rootfs:
  - A systemd preset (`50-acl-kdump.preset`) that enables `kdump.service`.
  - A `kdump.service` drop-in (`10-acl-kdump.conf`) gated on
    `ConditionKernelCommandLine=crashkernel`, so the service only arms the
    capture kernel when the `crashkernel=` cmdline is present.
  - `/etc/kdump.conf`, `/etc/sysconfig/kdump`, and a `tmpfiles.d` entry that
    create `/var/crash` and point `KDUMP_BOOTDIR` there.
- **`_uki_build_kdump_addon`** (`build_library/rpm/uki_install.sh`) builds the
  `kdump.addon.efi` template (carrying `crashkernel=256M`) and saves it on the
  ESP at `acl/uki-addons/kdump.addon.efi` — deliberately **not** in
  systemd-boot's auto-discovery directory, so it has no effect until you enable
  it as described above.

### Why `/var/crash` instead of `/boot`

On ACL's immutable rootfs, `/usr` is a read-only dm-verity btrfs filesystem and
`/boot` is a small vfat ESP. Neither can host the kdump capture kernel or its
dracut-generated initramfs. ACL therefore redirects `KDUMP_BOOTDIR` to
`/var/crash` on the writable ext4 ROOT partition. The `kdump.service` drop-in
copies the kernel binary there (via `ExecStartPre`) before `kdumpctl` runs, and
`vmcore` dumps are written to `/var/crash` as well.

## Related files

| File                                                             | Purpose                                                |
| ---------------------------------------------------------------- | ------------------------------------------------------ |
| `build_library/rpm/build_image_util.sh` (`_configure_kdump_rpm`) | In-image kdump service, config, and `/var/crash` setup |
| `build_library/rpm/uki_install.sh` (`_uki_build_kdump_addon`)    | Builds the `crashkernel=256M` UKI addon template       |
| `build_library/rpm/sign_uki_ephemeral.sh`                        | Signs UKI addons (incl. kdump) for Secure Boot         |
