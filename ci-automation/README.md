# CI automation glue logic scripts

Scripts in this directory aim to ease automation of Flatcar builds in continuous integration systems.

Each script represents a distinct build step; each step ingests the container image of the previous step and produces a new container image for the next step.
Notable exceptions are "SDK Bootstrap" (`sdk.sh`) which only creates an SDK tarball, and "VMs build" which does not output a container but only VM (vendor) images.

Please refer to the individual scripts for prerequisites, input parameters, and outputs.

All steps make use of a "build cache" server for pulling (https) and pushing (rsync) build inputs and artifacts.

## Build steps

The build pipeline can be used to build everything from scratch, including the SDK (starting from 1. below) or to build a new OS image (starting from 3.).

### SDK bootstrap build

1. SDK Bootstrap (`sdk.sh`): Use a seed SDK tarball and seed SDK container image to build a new SDK tarball.
   The resulting SDK tarball will use packages and versions pinned in the coreos-overlay and portage-stable submodules.
   This step updates the versionfile, recording the SDK container version just built.
   It will generate and push a new version tag to the scripts repo.
2. SDK container build (`sdk_container.sh`) : use SDK tarball to build an SDK container image.
   The resulting image will come in "amd64", "arm64", and "all" flavours, with support for respective OS target architectures. This step builds the Flatcar SDK container images published at ghcr.io/flatcar-linux.

```
         .---------.                 .------------.
         | scripts |                 |     CI     |
         |  repo   |                 | automation |
         `---------´                 `------------´
              |                             |
              |                   "alpha-3449.0.0-dev23"
              |                             |
              |                      _______v_______
              +------- clone -----> ( SDK bootstrap )
              |                      `-------------´
              |<- tag: sdk-3499.0.0-dev23 -´|
              |                             |
              |                      _______v_______
              +--      clone     -> ( SDK container )
              | sdk-3499.0.0-dev23   `-------------´
              |                             |
              v                             v
                      continue to OS
                       image build
                            |
                            v 
```

### OS image build

3. Packages build (`packages.sh`): using the SDK container version recorded in the versionfile, build OS image packages and generate a new container image (containing both SDK and packages).
   This step updates the versionfile, recording the Flatcar OS image version just built.
   It will generate and push a new version tag to the scripts repo.
4. Image build (`image.sh`): Using the container from 3., build an OS image and torcx store, and generate a new container image with everything in it.
5. VMs build (`vms.sh`). Using the packages+torcx+image container from 4., build vendor images. Results are vendor-specific OS images.

```
       .---------.                     .------------.
       | scripts |                     |     CI     |
       |  repo   |                     | automation |
       `---------´                     `------------´
            |                                 |
            |                       "alpha-3449.0.0-dev23"
            |                                 |
            |                             ____v_____
            +---------- clone -------->  ( packages )
            |                             `--------´
            |<-- tag: alpha-3499.0.0-dev23 --´|
            |                                 |
            |                              ___v___
            +-----       clone      --->  ( image )
            |    alpha-3499.0.0-dev23      `-----´
            |                                 |
            |                               __v__
            +-----       clone      --->   ( vms )
                 alpha-3499.0.0-dev23       `---´
```
