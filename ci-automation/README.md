# CI automation glue logic scripts

Scripts in this directory aim to ease automation of Flatcar builds in continuous integration systems.

Design goal of the automation scripts is to provide self-contained, context-aware automation with a low integration overhead.
Each step takes its context from the repository (version to build etc.) and from the artifact of the previous build, with the aim of reducing the number of arguments to an absolute minimum.

Each script represents a distinct build step; each step ingests the container image of the previous step and produces a new container image for the next step.
Notable exceptions are "SDK Bootstrap" (`sdk.sh`) which only creates an SDK tarball, and "VMs build" which does not output a container but only VM (vendor) images.
The container images are self-contained and aim for ease of reproducibility.
All steps make use of a "build cache" server for pulling (https) build inputs and for pushing (rsync) artifacts.

Test automation is provided alongside build automation, following the same design principles.

Please refer to the individual scripts for prerequisites, input parameters, and outputs.


## Build steps

The build pipeline can be used to build everything from scratch, including the SDK (starting from 1. below) or to build a new OS image (starting from 3.).
"From scratch" builds (i.e. builds which include a new SDK) are usually only done for the `main` branch (`main` can be considered `alpha-next`).
Release / maintenance branches in the majority of cases do note build a new SDK but start with the OS image build.
Release branches usually use the SDK introduced when the new major version was branched off `main` throughout the lifetime of the major version; i.e. release `stable-MMMM.mm.pp` would use `SDK-MMMM.0.0`.

To reproduce any given build step, follow this pattern:
```
./checkout <build-tag> # Build tag from either SDK bootstrap pr Packages step
source ci-automation/<step-script>.sh
<step_function> <parameters>
```

For example, to rebuild the AMD64 OS image of build `main-3145.0.0-nightly-20220209-0139`, do
```
./checkout main-3145.0.0-nightly-20220209-0139
source ci-automation/image.sh
image_build amd64
```

### SDK bootstrap build

1. SDK Bootstrap (`sdk.sh`): Use a seed SDK tarball and seed SDK container image to build a new SDK tarball.
   The resulting SDK tarball will use packages and versions pinned in the coreos-overlay and portage-stable submodules.
   This step updates the versionfile, recording the SDK container version just built.
   It will generate and push a new version tag to the scripts repo.
2. SDK container build (`sdk_container.sh`) : use SDK tarball to build an SDK container image.
   The resulting image will come in "amd64", "arm64", and "all" flavours, with support for respective OS target architectures. This step builds the Flatcar SDK container images published at ghcr.io/flatcar-linux.

```
         .---------.                    .------------.          .--------.
         | scripts |                    |     CI     |          |  Build |
         |  repo   |                    | automation |          |  cache |
         `---------´                    `------------´          `--------´
              |                                |                     |
              |                      "alpha-3449.0.0-dev23"          |
              |                                |                     |
              |                         _______v_______              |
              +-------- clone -------> ( SDK bootstrap )             |
              |                         `-------------´              |
              |<- tag: alpha-3499.0.0-dev23 --´|`--- sdk tarball --->|
              |                                |                     |
              |                         _______v_______              |
              +-------- clone -------> ( SDK container )             |
              | alpha-3499.0.0-dev23    `-------------´              |
              |                                |`- sdk container --->|
              v                                v        image
                      continue to OS
                       image build
                            |
                            v 
```

### OS image build

3. Packages build (`packages.sh`): using the SDK container version recorded in the versionfile, build OS image packages and generate a new container image (containing both SDK and packages).
   This step updates the versionfile, recording the Flatcar OS image version just built.
   It will generate and push a new version tag to the scripts repo.
4. Packages are published and the generic OS image is built.
   1. Binary packages are published (`push_pkgs.sh`) to the build cache, making them available to developers who base their work on the main branch.
   2. Image build (`image.sh`): Using the container from 3., build an OS image and torcx store, and generate a new container image with everything in it.
5. VMs build (`vms.sh`). Using the packages+torcx+image container from 4., build vendor images. Results are vendor-specific OS images.

```
       .---------.                     .------------.             .--------.
       | scripts |                     |     CI     |             |  Build |
       |  repo   |                     | automation |             |  cache |
       `---------´                     `------------´             `--------´
            |                                 |                        |
            |                       "alpha-3449.0.0-dev23"             |
            |                                 |                        |
            |                             ____v_____                   |
            +---------- clone -------->  ( packages )                  |
            |                             `--------´                   |
            |<-- tag: alpha-3499.0.0-dev23 --´|`- sdk + OS packages -->|
            |                                 |    container image     |
            |                                 |    torcx manifest      |
            |                           ______v_______                 |
            |                          ( publish pkgs )                |
            |                           `------------´                 |
            |                                 |`-- binary packages --->|
            |                              ___v__                      |
            +-----       clone      --->  ( image )                    |
            |    alpha-3499.0.0-dev23      `-----´                     |
            |                                 |`-- sdk + packages + -->|
            |                               __v__  OS image cnt img    |
            +-----       clone      --->   ( vms )                     |
                 alpha-3499.0.0-dev23       `---´                      |
                                              `- vendor OS images ---->|
```

## Testing

Testing follows the same design principles build automation adheres to - it's self-contained and context-aware, reducing required parameters to a minimum.
The `test.sh` script needs exactly two parameters: the architecture, and the image type to be tested.
Optionally, patterns matching a group of tests can be supplied (or simply a list of tests); this defaults to "all tests" of a given vendor / image.
`test.sh` also supports re-running failed tests automatically to reduce the need for human interaction on flaky tests.

Testing is implemented in two layers:
1. `ci-automation/test.sh` is a generic test wrapper / stub to be called from CI.
2. `ci-automation/vendor-testing/` contains low-level vendor-specific test wrappers around [`kola`](https://github.com/flatcar-linux/mantle/tree/flatcar-master/kola/), our test scenario orchestrator.

Testing relies on the SDK container and will use tools / test suites from the SDK.
The low-level vendor / image specific script (layer 2. in the list above) runs inside the SDK.
Testing will use the vendor image published by `vms.sh` from buildcache, and the torcx manifest published by `packages.sh`.

Additionally, a script library is provided (at `ci-automation/tapfile_helper_lib.sh`) to help handling `.tap` test result files produced by test runs.
Library functions may be used to merge the result of multiple test runs (e.g. for multiple image types / vendors) into a single test result report.
The test runs are considered successful only if all tests succeeded for all vendors / images at least once.


**Usage**
```
./checkout <version-to-test>
source ci-automation/test.sh
test_run <arch> <image-type>
```

E.g. for running qemu / amd64 tests on `main-3145.0.0-nightly-20220209-0139`:
```
./checkout main-3145.0.0-nightly-20220209-0139
source ci-automation/test.sh
test_run amd64 qemu
```

### QEmu test

`ci-automation/vendor-testing/qemu.sh` implements a `kola` wrapper for testing the `qemu` image.
The wrapper is a straightforward call to `kola` and does not have any additional requirements.

**NOTE** that the generic image (`flatcar_production_image.bin`) is used for the test instead of the QEmu vendor image.

**NOTE on host firewalling** The test automation uses bridged networking and will handle forwarding and NAT.
However, we experienced test failures from lack of internet access with several firewall implementations.
It is recommended to stop firewalling on the host the tests are run on (for example, use `systemctl stop firewalld` if the host used `firewalld`).

**Settings**

* `QEMU_IMAGE_NAME` - file name of the QEmu image to fetch from bincache.
* `QEMU_PARALLEL` - Number of parallel test cases to run.
                  Note that test cases may involve launching mutliple QEmu VMs (network testing etc.).
                  Tests are memory bound, not CPU bound; e.g. `20` is a sensible value for a 6 core / 12 threads systwem w/ 32 GB RAM.
