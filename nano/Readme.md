# Flatcar Nano experimental image

Current status
- It builds and boots. No tests.

- Probably more packages could be removed.
  - Bash is in there b/c dracut claims it needs Bash.
  - Lots of deps b/c of a full-featured systemd build.
    A minimal one would allow us to remove more packages, e.g. PAM etc...

Image packages definition is in
[`sdk_container/src/third_party/coreos-overlay/coreos-base/flatcar-nano/flatcar-nano-0.0.1-r1.ebuild`](sdk_container/src/third_party/coreos-overlay/coreos-base/flatcar-nano/flatcar-nano-0.0.1-r1.ebuild).

NOTE: flatcar-nano uses different USE flags to be extra lean.
See 
[`sdk_container/src/third_party/coreos-overlay/profiles/coreos/base/package.use.force`](sdk_container/src/third_party/coreos-overlay/profiles/coreos/base/package.use.force)
for details.
Core packages need a rebuild on order for this to work (hence the --[...]use flags).


To build, run
```
#  emerge-amd64-usr --unmerge util-linux cryptsetup lvm2
#  USE="-cryptsetup" emerge-amd64-usr --newuse --changed-use util-linux
emerge-amd64-usr --newuse --changed-use --buildpkg flatcar-nano util-linux cryptsetup lvm2 baselayout curl nghttp2
./build_image --base_pkg=coreos-base/flatcar-nano --base_sysext="" --replace
./image_to_vm.sh --from=../build/images/amd64-usr/latest --board=amd64-usr --image_compression_formats none
```

To run,
* start with -snapshot
* use `nano.json` ignition config which
  * ships passwords for root and core users (password is `core`)
  * fixes PAM so local TTY login works

# Next steps
- Manual testing, e.g. try to add image to a Kubernetes cluster using sysext.


