# Preloading Container Images into an ACL Image

This guide shows how to bake OCI container images into the containerd content
store of an existing Azure Container Linux (ACL) image, so that they are already
present on first boot and never need to be pulled from a registry.

This is useful for:

- Reducing pod start latency for images that are always needed (for example
  `pause`, CNI, or CSI images).
- Building nodes that can start workloads without registry connectivity.

The approach uses the [Azure Linux Image Customizer][ic] (IC). IC has no
built-in support for OCI or containerd preloading, but its `postCustomization`
hook runs in a chroot on the target root filesystem with `/usr`, `/proc`,
`/sys`, `/dev`, and `/run` mounted, loop devices available, and working
networking. That is enough to run the image's own containerd and pull directly
into `/var/lib/containerd`.

## Overview

1. Obtain an ACL image. IC accepts `vhd`, `vhdx`, `qcow2`, and raw directly, so
   a Marketplace VHD needs no conversion -- see
   [Download an Azure Marketplace Image][dl] for the export procedure.
2. Run IC with a single `postCustomization` script that starts the image's own
   containerd inside the chroot, pulls the images, and pins them.
3. Inspect the output image, then boot it and confirm with `ctr` / `crictl`.
4. Publish the result to an Azure Compute Gallery.

The script must use the **containerd binaries shipped in the target image**. The
metadata store is a bolt database whose schema is tied to the containerd
version; hydrating with a different version can produce a store the image's
containerd will not recover. Because the script runs inside the image, this
happens naturally.

## ACL Marketplace images

ACL ships under the `MicrosoftCBLMariner` publisher and the `azure-linux-3`
offer, with a separate Generation 2 SKU per architecture:

| Architecture | SKU                            | Example URN                                                                    |
| ------------ | ------------------------------ | ------------------------------------------------------------------------------ |
| x64          | `azure-linux-3-acl`            | `MicrosoftCBLMariner:azure-linux-3:azure-linux-3-acl:3.20260706.01`            |
| Arm64        | `azure-linux-3-arm64-gen2-acl` | `MicrosoftCBLMariner:azure-linux-3:azure-linux-3-arm64-gen2-acl:3.20260706.01` |

Both SKUs are versioned in lockstep. To confirm the current SKU list and the
available versions for one:

```sh
az vm image list-skus -l westus3 \
  -p MicrosoftCBLMariner -f azure-linux-3 -o table

az vm image list \
  --publisher MicrosoftCBLMariner \
  --offer azure-linux-3 \
  --sku azure-linux-3-acl \
  --all -o table
```

The exported image is a ~30 GB **fixed-format** VHD. `qemu-img` misdetects it as
`raw`, so pass `-f vpc` explicitly when inspecting it.

## Prerequisites

A Linux host with:

- Docker (to run the Image Customizer container)
- `qemu-img`, `qemu-nbd`, and `qemu-system-x86_64` with OVMF, if you want to
  verify or boot-test the result
- The `az` CLI, to obtain the input image and to publish the result

> **Note**
> Run IC from the published container image, not from an extracted binary. The
> ACL root filesystem uses the ext4 `orphan_file` feature, and `e2fsck` older
> than 1.47 fails on it with exit code 12 (`unsupported feature(s): FEATURE_C12`). The IC container ships a new enough e2fsprogs.

## 1. Write the preload script

The list of images to preload lives in its own file, one reference per line, so
it can be edited without touching the script.

`staging/images.txt`:

```text
# One image reference per line. Blank lines and # comments are ignored.
mcr.microsoft.com/oss/v2/kubernetes/pause:v3.10
mcr.microsoft.com/azurelinux/base/core:3.0
```

A preloaded image is only used if the reference matches the one the runtime
actually requests -- the store is keyed by reference, not by content. This
matters most for the sandbox (`pause`) image, since a mismatch there means every
pod start reaches out to a registry even though a byte-identical image is
already local.

ACL's `/usr/share/containerd/config.toml` does not pin the sandbox image, so the
effective value is containerd's compiled-in default unless the Kubernetes layer
overrides it. On containerd 2.x that default is **`registry.k8s.io/pause:3.10.1`**,
not an MCR reference. Note that containerd 2.x renamed the setting: the old
`sandbox_image` key under `io.containerd.grpc.v1.cri` no longer exists, so
grepping for it returns nothing. Query the current name instead:

```console
$ containerd config dump | grep -A1 pinned_images
    [plugins.'io.containerd.cri.v1.images'.pinned_images]
      sandbox = 'registry.k8s.io/pause:3.10.1'
```

Preload whatever that command reports. The `pause` entry in the example above
assumes an AKS-style deployment, where the Kubernetes layer drops its own
containerd configuration pointing at MCR; on a bare ACL image it will not match.

`staging/preload.sh`:

```sh
#!/bin/sh
set -eux

SYSEXT=/usr/share/distro/sysext/containerd.raw
SX=/mnt/sx
SOCK=/run/ctrd/c.sock
PLATFORM=linux/amd64          # linux/arm64 for the Arm64 ACL SKU

# IC bind-mounts the config file's parent directory at /_imageconfigs while
# scripts run, so the image list is read from there rather than baked in.
IMAGE_LIST=/_imageconfigs/images.txt

# /etc is created empty by the Image Customizer, and the CA trust store is only
# populated on first boot. The paths under /etc/pki are Fedora-style symlinks
# back into /etc, so point Go's TLS stack at the real extracted bundle in /usr.
export SSL_CERT_FILE=/usr/share/distro/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem

# containerd ships as a system extension rather than in the base /usr tree, and
# systemd only merges it at boot. Loop-mount it to reach the binaries.
mkdir -p "$SX" /run/ctrd /var/lib/containerd
mount -o ro,loop "$SYSEXT" "$SX"

"$SX/usr/bin/containerd" --root /var/lib/containerd --state /run/ctrd \
  --address "$SOCK" > /tmp/ctrd.log 2>&1 &
CTRD_PID=$!

# Poll until the API answers rather than sleeping a fixed interval, and bail
# out immediately if containerd dies during startup.
i=0
until "$SX/usr/bin/ctr" -a "$SOCK" version >/dev/null 2>&1; do
  if ! kill -0 "$CTRD_PID" 2>/dev/null; then
    echo "containerd exited during startup" >&2
    cat /tmp/ctrd.log >&2
    exit 1
  fi
  i=$((i + 1))
  if [ "$i" -ge 60 ]; then
    echo "containerd did not become ready within 60s" >&2
    cat /tmp/ctrd.log >&2
    exit 1
  fi
  sleep 1
done

# Strip comments and blank lines. The final read returns non-zero if the file
# has no trailing newline, so guard the loop with a `|| [ -n "$ref" ]`.
while read -r ref || [ -n "$ref" ]; do
  ref=${ref%%#*}
  ref=$(echo "$ref" | tr -d '[:space:]')
  [ -n "$ref" ] || continue

  "$SX/usr/bin/ctr" -a "$SOCK" -n k8s.io images pull \
    --snapshotter overlayfs --platform "$PLATFORM" "$ref"
  "$SX/usr/bin/ctr" -a "$SOCK" -n k8s.io images label \
    "$ref" io.cri-containerd.pinned=pinned
done < "$IMAGE_LIST"

"$SX/usr/bin/ctr" -a "$SOCK" -n k8s.io images ls

# Wait for containerd to exit before unmounting. The metadata store is a bolt
# database; killing it mid-write can leave the store unrecoverable.
kill "$CTRD_PID"
i=0
while kill -0 "$CTRD_PID" 2>/dev/null; do
  i=$((i + 1))
  if [ "$i" -ge 30 ]; then
    echo "containerd did not exit within 30s" >&2
    exit 1
  fi
  sleep 1
done
wait "$CTRD_PID" 2>/dev/null || true

umount "$SX"; rmdir "$SX"
rm -rf /run/ctrd /tmp/ctrd.log

# Use numeric IDs. ACL's factory /etc is staged under /usr/share/distro/etc and
# is only materialized at /etc on first boot, so name lookups fail here and a
# symbolic `chown root:root` reports "invalid user".
#
# Neither of these is recursive, and deliberately so: containerd already owns
# everything it created, and the snapshot tree holds extracted image layers
# whose per-file uid/gid and modes come from the image itself. A recursive
# `chown`/`chmod` would rewrite those and corrupt the preloaded images.
chown 0:0 /var/lib/containerd
chmod 700 /var/lib/containerd
```

Notes:

- `images.txt` sits next to `config.yaml`; IC bind-mounts that directory at
  `/_imageconfigs` inside the chroot for the duration of the script, so nothing
  needs to be copied into the image or cleaned up afterwards.
- Images must be pulled into the `k8s.io` namespace, which is what the CRI
  plugin uses.
- `ctr` 2.x unpacks the snapshot as part of `pull`; there is no separate
  `ctr images unpack` step.
- The `io.cri-containerd.pinned=pinned` label prevents kubelet's image garbage
  collector from evicting the preloaded images.
- The snapshotter must match what the image's containerd is configured to use
  (`overlayfs` by default).
- containerd writes only to `/var/lib/containerd` and `/run/ctrd`, both of which
  are cleaned up or intended to persist, so the script leaves no other residue.
- `--platform` must match the image being customized. Because the script runs
  the target image's own `containerd` and `ctr` binaries, customizing an Arm64
  ACL image is most straightforward from an Arm64 build host; doing it from x64
  additionally requires `binfmt_misc` and a static `qemu-user` interpreter so
  the chroot can execute those binaries.

## 2. Run the Image Customizer

`staging/config.yaml`:

```yaml
previewFeatures:
  - preview-distro-version
  - uki
  - reinitialize-verity

storage:
  # ACL's root partition is not verity-protected; leaving verity untouched
  # avoids invalidating the existing signatures.
  reinitializeVerity: none

os:
  uki:
    # Reuse the existing signed UKI instead of regenerating (and unsigning) it.
    mode: passthrough

scripts:
  postCustomization:
    - path: preload.sh
```

`path` is used here because the script is long; shorter scripts can be inlined
with `content:` instead. Scripts run under `/bin/sh` by default.

```sh
# The build directory MUST live on its own mount -- see the note below.
sudo mkdir -p /mnt/bd
sudo mount -t tmpfs -o size=70G tmpfs /mnt/bd

# docker run reuses a cached tag, so refresh it explicitly.
sudo docker pull mcr.microsoft.com/azurelinux/imagecustomizer:latest

sudo docker run --rm --privileged=true \
  -v /dev:/dev \
  -v /mnt/bd:/mnt/bd \
  -v "$PWD/staging:/staging" \
  mcr.microsoft.com/azurelinux/imagecustomizer:latest \
  customize \
  --image-file /staging/acl.vhd \
  --config-file /staging/config.yaml \
  --build-dir /mnt/bd \
  --output-image-format vhd-fixed \
  --output-image-file /staging/out/acl-preloaded.vhd
```

ACL support needs Image Customizer 1.5.0 or newer. `latest` currently satisfies
that; pin an explicit tag instead if the build needs to be reproducible.

Use `vhd-fixed`, not `vhd`, if the result is destined for an Azure Compute
Gallery: Azure only accepts fixed-size VHDs, and requires the virtual size to be
a whole number of MiB. IC satisfies both -- the output carries a `conectix`
footer, and the file is exactly the virtual size plus the 512-byte footer:

```console
$ qemu-img info -f vpc staging/out/acl-preloaded.vhd
file format: vpc
virtual size: 30.4 GiB (32633782272 bytes)   # 31122 MiB exactly
disk size: 624 MiB
```

The file is sparse, so it occupies only the written extents locally even though
it is nominally 30 GB.

Other formats (`qcow2`, `raw`, `vhdx`, `cosi`, ...) are available via the same
flag if the image is only going to be booted locally.

IC expands the input to raw in the build directory regardless of the input
format, so size the build mount for the image's full virtual size (~31 GB for
ACL) rather than for the compressed file on disk.

The cached container images from `ctr images ls` (run inside the chroot) are
listed in IC's `--log-level debug` output, which is a useful early check that
the pulls succeeded.

### Known issues and workarounds

| Symptom                                                                            | Cause                                                                                                                                                                                                          | Workaround                                                                                     |
| ---------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `too many levels of symbolic links` (`ELOOP`) during partition mount               | IC synthesizes ACL's missing mount directories with `lowerdir=<build-dir>/rootmountdirsdir:/`. Because the build directory is a descendant of `/`, the lowerdirs overlap, which overlayfs rejects as `-ELOOP`. | Put `--build-dir` on a separate mount, e.g. a tmpfs at `/mnt/bd`. A fix is in flight upstream. |
| `failed to find rootfs partition`                                                  | A locally cached `:latest` image that predates ACL support. `docker run` never re-pulls a tag it already has.                                                                                                  | `docker pull mcr.microsoft.com/azurelinux/imagecustomizer:latest`.                             |
| `e2fsck` exits 12, `unsupported feature(s): FEATURE_C12`                           | Host `e2fsprogs` is older than 1.47 and does not understand ext4 `orphan_file`.                                                                                                                                | Run IC from the container image.                                                               |
| `tls: failed to verify certificate: x509: certificate signed by unknown authority` | `/etc` is empty during `postCustomization`; the CA trust store is generated on first boot.                                                                                                                     | `export SSL_CERT_FILE=/usr/share/distro/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem`.     |
| `chown: invalid user 'root:root'`                                                  | `/etc` is empty during `postCustomization`; ACL's `passwd` lives under `/usr/share/distro/etc` and is not materialized at `/etc` until first boot, so name lookups fail.                                       | Use numeric IDs: `chown 0:0`.                                                                  |
| `source (.../snapshots/1/fs/bin) is not a file`                                    | `os.additionalDirs` cannot copy symlinks (relevant only to the offline variant below).                                                                                                                         | Ship a tarball via `os.additionalFiles` and unpack it in a `postCustomization` script.         |

ACL images also require `preview-distro-version` in `previewFeatures`, and the
Docker invocation needs `--privileged=true -v /dev:/dev`.

## 3. Verify

Two checks, in increasing order of cost. The first needs no VM and is cheap
enough to run on every build; the second confirms the image's own containerd
actually recovers the store.

### Inspect the output image without booting

```sh
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 --read-only -f vpc staging/out/acl-preloaded.vhd
sudo mkdir -p /mnt/verify
sudo mount -o ro /dev/nbd0p5 /mnt/verify   # ROOT is the fifth partition

ls -la /mnt/verify/var/lib/containerd
strings /mnt/verify/var/lib/containerd/io.containerd.metadata.v1.bolt/meta.db \
  | grep -E 'mcr\.microsoft\.com|pinned'
```

Confirm the directory is `0700` `root:root`. This proves the content landed in
the image, but not that containerd will accept it -- for that, boot it.

### Local boot check

systemd starts, merges the containerd sysext, and the CRI plugin recovers the
store, which is exactly the path being validated. Three concessions are made to
run this locally:

- ACL has no default console login, so systemd's debug shell is enabled on a
  second serial port.
- The image boots from a signed UKI, so kernel arguments cannot be appended
  without re-signing it. Booting the extracted kernel and initrd directly with
  `-kernel`/`-initrd` sidesteps that.
- The image's first-boot and OEM-selection UKI addons live on the ESP in
  `EFI/Linux/<uki>.efi.extra.d/` and are merged into the command line by
  systemd-stub. Booting with `-kernel`/`-initrd` bypasses systemd-stub, so the
  kernel sees only the UKI's baked-in command line. The boot therefore takes
  the *subsequent* boot path (`ignition-subsequent.target`), no OEM is
  selected, and no provisioning runs.

None of these change what containerd does, so this remains a valid check that
the preloaded store is recovered. It is not a test of the boot path a real
Azure VM takes.

> **Note**
> The addons are present and intact in the customized image -- Image Customizer
> does not disturb them, and a real Azure deployment boots through
> systemd-boot and picks them up:
>
> | ESP path                                          | Injects                              |
> | ------------------------------------------------- | ------------------------------------ |
> | `EFI/Linux/<uki>.efi.extra.d/firstboot.addon.efi` | `flatcar.first_boot=detected`        |
> | `EFI/Linux/<uki>.efi.extra.d/oem.addon.efi`       | `flatcar.oem.id=azure`, console args |
>
> Do not try to make the local check "more realistic" by appending these by
> hand. Ignition then runs for real, resolves the `azure` platform, and blocks
> fetching `http://169.254.169.254/metadata/instance/compute/userData`.
> `ignition-fetch.service` has no timeout, so under plain QEMU the boot hangs
> in the initrd indefinitely and never reaches `multi-user.target`. Bypassing
> the addons is what makes the local check usable at all.
>
> Provisioning behaviour can only be validated by deploying the published
> gallery image version (below) as an Azure VM.

Extract the kernel, initrd, and command line from the UKI on the ESP:

```sh
objcopy -O binary --only-section=.linux   uki.efi vmlinuz
objcopy -O binary --only-section=.initrd  uki.efi initrd
objcopy -O binary --only-section=.cmdline uki.efi cmdline
```

Boot a scratch copy (never the artifact itself -- the boot mutates it),
appending the debug-shell options to the extracted command line:

```sh
cp --sparse=always staging/out/acl-preloaded.vhd test.vhd

qemu-system-x86_64 -machine q35,accel=kvm -cpu host -smp 4 -m 4096 \
  -drive file=test.vhd,format=vpc,if=virtio \
  -kernel vmlinuz -initrd initrd \
  -append "$(cat cmdline) console=ttyS0,115200 \
            systemd.debug-shell=ttyS1 systemd.setup-debug-shell=1" \
  -serial file:boot.log \
  -serial unix:/tmp/acl.sock,server,nowait \
  -display none
```

Connect to `/tmp/acl.sock` and confirm:

```console
# ctr -n k8s.io -a /run/containerd/containerd.sock images ls
REF                                              SIZE      LABELS
mcr.microsoft.com/azurelinux/base/core:3.0       30.3 MiB  io.cri-containerd.pinned=pinned
mcr.microsoft.com/oss/v2/kubernetes/pause:v3.10   6.2 MiB  io.cri-containerd.pinned=pinned

# crictl images
IMAGE                                       TAG     IMAGE ID        SIZE
mcr.microsoft.com/azurelinux/base/core      3.0     2b36a7c9158cd   31.8MB
mcr.microsoft.com/oss/v2/kubernetes/pause   v3.10   fc42a8735dcaf   6.55MB
```

The boot log should also show the CRI plugin recovering the images:

```
containerd successfully booted
ImageUpdate name:"mcr.microsoft.com/oss/v2/kubernetes/pause:v3.10" io.cri-containerd.pinned=pinned
```

This confirms the image's own containerd accepts the preloaded store. Whether
`/var` survives a real provisioning cycle is a separate question that this check
does not answer -- deploy the gallery image version as an Azure VM and re-run
`ctr images ls` to confirm it.

## 4. Publish to an Azure Compute Gallery

Upload the fixed VHD as a page blob, then reference that blob directly as the
source for a gallery image version.

```sh
RG=my-images
LOC=westus3
SA=myimagestorage
CONTAINER=vhds
BLOB=acl-preloaded.vhd

az storage account create -g "$RG" -n "$SA" -l "$LOC" --sku Standard_LRS
az storage container create --account-name "$SA" -n "$CONTAINER" --auth-mode login

azcopy copy staging/out/acl-preloaded.vhd \
  "https://$SA.blob.core.windows.net/$CONTAINER/$BLOB" \
  --blob-type PageBlob
```

`azcopy` skips the unwritten extents of the sparse file, so the upload moves
roughly the size on disk rather than the full 30 GB.

Create the image definition once, matching the architecture and generation of
the image you customized, then add a version per build:

```sh
az sig image-definition create -g "$RG" \
  --gallery-name mygallery --gallery-image-definition acl-preloaded \
  --publisher myorg --offer acl --sku preloaded \
  --os-type Linux --os-state generalized \
  --hyper-v-generation V2 --architecture x64      # or Arm64

SA_ID=$(az storage account show -g "$RG" -n "$SA" --query id -o tsv)

az sig image-version create -g "$RG" \
  --gallery-name mygallery --gallery-image-definition acl-preloaded \
  --gallery-image-version 1.0.0 \
  --os-vhd-storage-account "$SA_ID" \
  --os-vhd-uri "https://$SA.blob.core.windows.net/$CONTAINER/$BLOB"
```

This is why `vhd-fixed` matters. Azure accepts only fixed-size VHDs whose
virtual size is a whole number of MiB; a dynamic VHD is rejected.

> A managed disk created with `--upload-type Upload` works as a source too, via
> `--os-snapshot`, but it requires passing the exact byte count through
> `--upload-size-bytes`. Uploading to a blob avoids that step.

## Appendix: offline (air-gapped) variant

If the build host cannot reach the registry from inside the IC chroot -- for
example in an air-gapped pipeline, or where egress is only permitted from the
build host itself -- hydrate the containerd data root out of band and inject it
as a tarball instead.

Extract containerd from the image's sysext:

```sh
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 --read-only -f vpc staging/acl.vhd

# USR-A is the second partition on the ACL GPT layout.
sudo mkdir -p /mnt/usr /mnt/sysext
sudo mount -o ro /dev/nbd0p2 /mnt/usr

# Copy the sysext out before mounting it; loop-mounting a file that lives on
# an nbd-backed btrfs mount can hang.
cp /mnt/usr/share/distro/sysext/containerd.raw /tmp/containerd.raw
sudo mount -o ro,loop /tmp/containerd.raw /mnt/sysext
cp /mnt/sysext/usr/bin/containerd /mnt/sysext/usr/bin/ctr work/bin/

sudo umount /mnt/sysext /mnt/usr
sudo qemu-nbd --disconnect /dev/nbd0
```

Hydrate a scratch data root on the host with the extracted binaries, using the
same pull and label sequence as the in-chroot script. The whole block runs under
a single `sudo` so that containerd is a direct child of the shell: backgrounding
`sudo containerd` instead would make `$!` the PID of `sudo` rather than of
containerd, and the shutdown wait would then hang.

```sh
sudo sh -eux <<'EOF'
SOCK=/run/ctrd-host/c.sock
PLATFORM=linux/amd64
IMAGE_LIST=staging/images.txt

mkdir -p /run/ctrd-host staging/ctrd-root
work/bin/containerd --root "$PWD/staging/ctrd-root" \
  --state /run/ctrd-host --address "$SOCK" > /tmp/ctrd-host.log 2>&1 &
CTRD_PID=$!

until work/bin/ctr -a "$SOCK" version >/dev/null 2>&1; do
  kill -0 "$CTRD_PID" 2>/dev/null || { cat /tmp/ctrd-host.log >&2; exit 1; }
  sleep 1
done

while read -r ref || [ -n "$ref" ]; do
  ref=${ref%%#*}
  ref=$(echo "$ref" | tr -d '[:space:]')
  [ -n "$ref" ] || continue

  work/bin/ctr -a "$SOCK" -n k8s.io images pull \
    --snapshotter overlayfs --platform "$PLATFORM" "$ref"
  work/bin/ctr -a "$SOCK" -n k8s.io images label \
    "$ref" io.cri-containerd.pinned=pinned
done < "$IMAGE_LIST"

kill "$CTRD_PID"
wait "$CTRD_PID" 2>/dev/null || true
EOF
```

Tar the result, preserving ownership and extended attributes:

```sh
sudo tar --numeric-owner --xattrs --xattrs-include='*' --acls \
  -cf staging/ctrd-root.tar -C staging ctrd-root
```

Ship it via `os.additionalFiles` (not `additionalDirs`, which cannot copy
symlinks) and unpack it in `postCustomization`. The unpack script is short
enough to inline with `content:` rather than shipping a separate file:

```yaml
os:
  additionalFiles:
    - source: ctrd-root.tar
      destination: /ctrd-root.tar
      permissions: "600"

scripts:
  postCustomization:
    - name: extract-containerd-root
      content: |
        set -eux
        rm -rf /var/lib/containerd
        tar --numeric-owner --xattrs --xattrs-include='*' --acls \
          -xf /ctrd-root.tar -C /var/lib
        mv /var/lib/ctrd-root /var/lib/containerd
        chown 0:0 /var/lib/containerd
        chmod 700 /var/lib/containerd
        rm -f /ctrd-root.tar
```

Both variants produce an equivalent store; the in-chroot flow is preferred
because it needs no host-side containerd, no version matching, and no
multi-hundred-megabyte intermediate tarball.

[dl]: https://microsoft.github.io/azure-linux-image-tools/imagecustomizer/how-to/azure-vm/download-marketplace-image.html
[ic]: https://github.com/microsoft/azure-linux-image-tools
