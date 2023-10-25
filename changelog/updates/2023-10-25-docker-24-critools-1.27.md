- docker ([24.0.6](https://docs.docker.com/engine/release-notes/24.0/), includes changes from [23.0](https://docs.docker.com/engine/release-notes/23.0/))
  - **NOTE** The docker btrfs storage driver has been de-prioritised; BTRFS backed storage will now default to the `overlay2` driver
    ([changelog](https://docs.docker.com/engine/release-notes/23.0/#bug-fixes-and-enhancements-6), [upstream pr](https://github.com/moby/moby/pull/42661)).
    Using the btrfs driver can still be enforced by creating a respective [docker config](https://docs.docker.com/storage/storagedriver/btrfs-driver/#configure-docker-to-use-the-btrfs-storage-driver) at `/etc/docker/daemon.json`.
- cri-tools ([1.27.0](https://github.com/kubernetes-sigs/cri-tools/releases/tag/v1.27.0))
