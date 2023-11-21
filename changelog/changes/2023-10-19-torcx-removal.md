- **torcx was replaced by systemd-sysext in the OS image**. Learn more about sysext and how to customise OS images [here](https://www.flatcar.org/docs/latest/provisioning/sysext/).
  - Torcx entered deprecation 2 years ago in favour of [deploying plain Docker binaries](https://www.flatcar.org/docs/latest/container-runtimes/use-a-custom-docker-or-containerd-version/)
    (which is now also a legacy option because systemd-sysext offers a more robust and better structured way of customisation, including OS independent updates).
  - Torcx has been removed entirely; if you use torcx to extend the Flatcar base OS image, please refer to our [conversion script](https://www.flatcar.org/docs/latest/provisioning/sysext/#torcx-deprecation) and to the sysext documentation mentioned above for migrating.
  - Consequently, `update_engine` will not perform torcx sanity checks post-update anymore.
  - Relevant changes: [scripts#1216](https://github.com/flatcar/scripts/pull/1216), [update_engine#30](https://github.com/flatcar/update_engine/pull/30), [Mantle#466](https://github.com/flatcar/mantle/pull/466), [Mantle#465](https://github.com/flatcar/mantle/pull/465).
