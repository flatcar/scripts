# Flatcar Nano experimental image

Current status
- It builds and it boots.
  Login via serial console works.
  All services included start successfully.
- 226 packages, ~600 MB `/usr` (~300p, ~990MB with stock Flatcar)

- Test on more clouds.
- Test without apps/net-tools (azure provisioning failure ?)
- make waagent openssh patch conditional to nano

- Probably more packages could be removed.
  - Bash is in there b/c dracut claims it needs Bash.
  - Lots of deps b/c of a full-featured systemd build.
    A minimal one would allow us to remove more packages, e.g. PAM etc...
- Some common tools packages are missing: awk, grep, ...
  Manage your expectations ;)
- Workarounds added to multiple ebuilds (`coreos-init` and friends) to accomodate for missing SSH.
  Check diff to main for full info.
- System reports "cgroupsv1 legacy mode" on login because MOTD cgroups mode detection uses Grep,
  and grep is not included in the image
  (see https://github.com/flatcar/init/blob/flatcar-master/scripts/motdgen#L26)

- coreos-metadata needs sed, so it's included. Research if that can be replaced with pure bash.


Image packages definition is in
[`sdk_container/src/third_party/coreos-overlay/coreos-base/flatcar-nano/flatcar-nano-0.0.1-r1.ebuild`](sdk_container/src/third_party/coreos-overlay/coreos-base/flatcar-nano/flatcar-nano-0.0.1-r1.ebuild).

NOTE: flatcar-nano uses different USE flags to be extra lean.
See 
[`sdk_container/src/third_party/coreos-overlay/profiles/coreos/base/package.use.force`](sdk_container/src/third_party/coreos-overlay/profiles/coreos/base/package.use.force)
for details.
Core packages need a rebuild on order for this to work (hence the --[...]use flags).


To build, run
```
emerge-amd64-usr --unmerge util-linux cryptsetup lvm2
USE="-cryptsetup" emerge-amd64-usr --newuse --changed-use util-linux
emerge-amd64-usr --newuse --changed-use --buildpkg flatcar-nano util-linux cryptsetup lvm2 baselayout curl nghttp2 grub shim shim-signed
./build_image --base_pkg=coreos-base/flatcar-nano --base_sysexts="" --replace
./image_to_vm.sh --from=../build/images/amd64-usr/latest --board=amd64-usr --image_compression_formats none
```

To run,
* start with -snapshot
* use `nano.json` ignition config which
  * ships passwords for root and core users (password is `core` for both)
  * fixes PAM so local TTY login works
```
cd __build__/images/images/amd64-usr/latest
./flatcar_production_qemu_uefi.sh -i ../../../../../nano/nano.json -- -snapshot -nographic
```

Login with user `core` password `core` after boot.
Use `su` to switch to root (password is also `core`); `sudo` isn't installed.


If you want to run container workloads, you'll need the containerd and docker sysexts.
For these, run:
```bash
emerge-amd64-usr --newuse --changed-use --buildpkg docker containerd docker-cli docker-buildx
./build_image --base_pkg=coreos-base/flatcar-nano --replace
./image_to_vm.sh --from=../build/images/amd64-usr/latest --board=amd64-usr --image_compression_formats none
```


# Next steps
- Move the PAM config changes currently in nano.json to the PAM (or the nano) ebuild
- Further drive down package count.
- Add sysexts for specific functions, e.g. openssh
- Manual testing, e.g. try to add image to a Kubernetes cluster using sysext.
- Test automation (new "distro"), find a way for remoting since SSH does not work
