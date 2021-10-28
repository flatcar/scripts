# Flatcar Container Linux SDK scripts

Welcome to the scripts repo, your starting place for most things here in the Flatcar Container Linux SDK. To get started you can find our documentation on [the Flatcar docs website][flatcar-docs].

The SDK can be used to
* patch or update applications or libraries included in the Flatcar OS image
* add or remove applications and / or libraries
* Modify the kernel configuration and add or remove kernel modules included with Flatcar
* Build OS images for a variety of targets (qemu, bare metal, AWS, Azure, VMWare, etc.)
* And lastly, the SDK can be used to upgrade SDK packages and to build new SDKs

[flatcar-docs]: https://docs.flatcar-linux.org/os/sdk-modifying-flatcar/


# Using the SDK container

We provide a containerised SDK via https://github.com/orgs/flatcar-linux/packages. The container comes in 3 flavours:
* Full SDK initialised with both architectures supported by Flatcar (amd64 and arm64). This is the largest container, it's about 7GB in size.
* AMD64 SDK initialised for building AMD64 OS images. About 5.5GB in size.
* ARM64 SDK initialised for building ARM64 OS images on AMD64 hosts. Also about 5.5GB in size. (While work on a ARM64 native SDK is ongoing, it's unfortunately not ready yet).

The container can be run in one of two ways - "standalone", or integrated with the [Scripts](https://github.com/flatcar-linux/scripts) repo:
* Standalone mode will use no host volumes and will allow you to play with the SDK in a sandboxed throw-away environment. In standalone mode, you interface with Docker directly to use the SDK container.
* Integrated mode will closely integrate with the Scripts directory and bind-mount it as well as the portage-stable and coreos-overlay gitmodules into the container. Integrated mode uses wrapper scripts to interact with the SDK container.

## Standalone mode

In standalone mode, the SDK is just another Docker container. Interaction with the container happens via use of `docker` directly. Use for experimenting and for throw-away work only, otherwise please use integrated mode (see below).

* Check the list of available versions and pick a version to use. The SDK Major versions correspond to Flatcar Major release versions.
  List of images: `https://github.com/orgs/flatcar-linux/packages/container/package/flatcar-sdk-all`
  For the purpose of this example we'll use version `3005.0.0`.
* Fetch the container image: `docker pull ghcr.io/flatcar-linux/flatcar-sdk-all:3005.0.0`
* Start the image in interactive (tty) mode: `docker run -ti ghcr.io/flatcar-linux/flatcar-sdk-all:3005.0.0`
  You are now inside the SDK container:
  `sdk@f236fda982a4 ~/trunk/src/scripts $`
* Initialise the SDK in self-contained mode. This needs to be done once per container and will check out the scripts, coreos-overlay, and portage-stable repositories into the container.
  `sdk@f236fda982a4 ../sdk_init_selfcontained.sh`

You can now work with the SDK container.

### Privileged mode when building images

In order to build OS images (via `./build_image` and `./image_to_vm`) the SDK tooling requires privileged access to `/dev`.
This is necessary because the SDK currently employs loop devices to create and to partition OS images.

To start a container in privileged mode with `/dev` available use:
* `docker run -ti  --privileged -v /dev:/dev ghcr.io/flatcar-linux/flatcar-sdk-all:3005.0.0`

## Integrated mode

This is the preferred mode of working with the SDK.
Interaction with the container happens via wrapper scripts from the Scripts repository.
Both the host's scripts repo as well as its submodules (portage-stable and coreos-overlay) are made available in the container, allowing for work on these repos directly.
The wrapper scripts will re-use existing containers instead of creating new ones to preserve your work in the container, enabling consistency.

To clone the scripts repo and pick a version:
* Clone the scripts repo: `git clone https://github.com/flatcar-linux/scripts.git`
* Optionally, check out a release tag to base your work on
  * list releases (e.g. all Alpha releases): `git tag -l alpha-*`
  * check out the release version, e.g. `3005.0.0`: `git checkout 3005.0.0`
* Update the overlay submodules: `git submodules update`

To use the SDK container:
* Fetch image and start the SDK container: `./run_sdk_container -t`
  This will fetch the container image of the "scripts" repo's release version you checked out.
  The `-t` command line flag will allocate a TTY, which is preferred for interactive use.
  The command will put you into the SDK container:
  `sdk@sdk-container ~/trunk/src/scripts $`
* Alternatively, you can run individual commands in the SDK container using `./run_sdk_container <command>` (e.g. `./run_sdk_container ./build_packages`).

Subsequent calls to `./run_sdk_container` will re-use the container (as long as the local release version check-out the scripts repo does not change).
Check out `docker container ls --all` and you'll see something like
```
CONTAINER ID   IMAGE                                            COMMAND                  CREATED       STATUS                         PORTS     NAMES
19ea3b6d00ad   ghcr.io/flatcar-linux/flatcar-sdk-all:3005.0.0   "/bin/sh -c /home/sd…"   4 hours ago   Exited (0) About an hour ago             flatcar-sdk-all-3005.0.0_os-3005.0.0
```

Re-use of containers happens on a per-name basis. The above example's container name `flatcar-sdk-all-3005.0.0_os-3005.0.0` is generated automatically. Using `docker container rm` the container can be discarded - a subsequent call to `./run_sdk_container` will create a new one.  Custom containers can be created by use of the `-n <name>` command line option; these will be re-used in subsequent calls to `./run_sdk_container` when using the same `<name>`.

The local sourcetree can also be used with an entirely custom SDK container image. Users must ensure that the image is either fetch-able or present locally. The custom image can be specified using `-C <custom-image>`. This option is useful e.g. for building the local sourcetree with different SDK versions.

Check out `./run_sdk_container -h` for more information on command line options.

# Building a new SDK container

Building an SDK container is done using `./build_sdk_container_image`.
The SDK container is based on an SDK tarball which the script will fetch.
By default, the current git tree's release version will be built; this can be changed with the `-v` flag.
When using `-v`, the corresponding release version of the Scripts repository is checked out (unless suppressed by `-c`) before the container is generated.

# Bootstrapping a new SDK tarball using the SDK container

The script `./bootstrap_sdk_container` bootstraps a new SDK tarball using an existing SDK container and seed tarball. Specifying the seed version is required for this script.
