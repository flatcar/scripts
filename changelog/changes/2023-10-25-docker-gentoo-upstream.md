- cri-tools, runc, containerd, docker, and docker-cli are now shipped without debugging symbols and built from Gentoo upstream ebuilds. Docker was updated to Docker 24 (see "updates").
  - **NOTE** The docker btrfs storage driver has been de-prioritised; BTRFS backed storage will now default to the `overlay2` driver
    ([changelog](https://docs.docker.com/engine/release-notes/23.0/#bug-fixes-and-enhancements-6), [upstream pr](https://github.com/moby/moby/pull/42661)).
    Using the btrfs driver can still be enforced by creating a respective [docker config](https://docs.docker.com/storage/storagedriver/btrfs-driver/#configure-docker-to-use-the-btrfs-storage-driver) at `/etc/docker/daemon.json`.
  - **NOTE that if you are using btrfs-backed Docker storage and are upgrading to this new version then the driver for that storage will change to `overlay2`.**
    To prevent this please create a respective docker daemon configuration file on affected nodes as discussed above.
