# ACL Documentation

Detailed documentation for Azure Container Linux.

| Document                        | Description                                                                  |
| ------------------------------- | ---------------------------------------------------------------------------- |
| [Architecture](architecture.md) | Overview, relationship with Flatcar, boot flow, dm-verity, Ignition, SELinux |
| [System Extensions](sysexts.md) | Base and standalone sysexts, GPU drivers                                     |
| [Platforms](platforms.md)       | Supported platforms and OEM packages                                         |
| [Testing](testing.md)           | Kola/Mantle framework, test categories, enforcing tests                      |
| [Kdump](kdump.md)               | Enabling crash dump (kdump) collection via the UKI addon                     |

## Operational Guides

| Document                                               | Description                                                           |
| ------------------------------------------------------ | --------------------------------------------------------------------- |
| [Build RPM Image](BUILD_RPM_IMAGE_README.md)           | Building ACL images from RPMs                                         |
| [Container Image Preload](containerd-image-preload.md) | Baking OCI images into the containerd store with the Image Customizer |
