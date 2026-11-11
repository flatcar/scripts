# Flatcar mkosi build — runs inside the SDK container

Builds Flatcar disk images with stock mkosi (27+). The Flatcar-specific steps
are script hooks that call the SDK's own tooling (`build_library/*`, the board
`emerge`), installing the board's binary packages from `/build/<board>`.

## Run it

From inside the SDK container, in this directory:

    mkosi genkey                      # once: mkosi.key/mkosi.crt sign the sysexts and confext
    mkosi build                       # production image, amd64
    mkosi --architecture=arm64 build  # arm64
    mkosi --profile oem-qemu build    # one vendor image, see mkosi.profiles/oem-*
    mkosi --profile extra-sysexts build

i.e. from the host: `./run_sdk_container … sudo mkosi build`. Build one `oem-*`
profile per run. The board needs the OS binary packages first
(`./build_packages`).

## How packages get installed

`Distribution=custom` installs nothing, so `tools/prepare.sh` reads `Packages=`
and `RemovePackages=` back from `$MKOSI_CONFIG` and calls the `tools/bin/mkosi-*`
helpers, which run the SDK's `emerge` into `$BUILDROOT`. With
`FLATCAR_SOURCE_BUILD=1` (the default), missing binary packages are built first.

## Layout

    mkosi.conf                  top-level disk image and the SDK sandbox setup
    mkosi.images/base/          the OS tree (coreos-base/coreos)
    mkosi.images/*-sysext/      built-in, extra and OEM sysexts
    mkosi.profiles/oem-*/       vendor images: OEM sysext, disk layout, output name
    mkosi.postinst.d/           build_image's steps for the final image, in order
    mkosi.finalize              verity'd /usr and its hash in the kernel
    mkosi.repart/               disk_layout.json's partitions
    include/                    settings shared by the sysexts and OEM profiles
    lib/lib.sh                  SDK environment and emerge helpers for the hooks
    tools/                      shared hooks and image_to_vm.sh conversions

## Debugging

`sudo mkosi box` opens a shell with the same sandbox binds (board sysroot, ebuild
repos, `/var/db/pkg`), but without `$BUILDROOT` or `$MKOSI_CONFIG`; for those,
point `PrepareScripts=` at a throwaway script. `MKOSI_DEBUG=1` traces the hooks.

## Gotchas

- The incremental cache doesn't track `mkosi.postinst.d/`, `mkosi.finalize`,
  `lib/` or `Environment=`: rebuild with `mkosi -ff` after changing them.
- `/build/<board>` lives in the SDK container's writable layer: removing the
  container loses the board and its binary packages.
- `BuildPackages=` and `VolatilePackages=` are not supported; `tools/prepare.sh`
  fails on them.
- `RemovePackages=` can't work in `Overlay=yes` images, which can't express
  deletions.
