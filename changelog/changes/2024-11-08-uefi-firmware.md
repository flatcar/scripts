- The UEFI firmware has changed from raw (.fd) format to QCOW2 format. In addition, the amd64 firmware variables are now held in a 4MB image rather than a 2MB image. Note that this firmware is only intended for testing with QEMU. Do not use it in production. ([scripts#2434](https://github.com/flatcar/scripts/pull/2434))
- The arm64 UEFI firmware now supports Secure Boot. Be aware that this is not considered secure due to the lack of an SMM implementation, which is needed to protect the variable store. As above, this firmware should not be used in production anyway. ([scripts#2434](https://github.com/flatcar/scripts/pull/2434))