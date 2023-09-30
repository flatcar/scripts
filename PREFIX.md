# Prefix - build portable, distro-independent apps

**!!! NOTE: Prefix support in the Flatcar SDK is EXPERIMENTAL at this time !!!**

## Path to stabilisation TODO list

Before prefix build support are considered stable, the below must be implemented:
1. Integrate `cb-bootstrap` with the Flatcar SDK.
   Currently, `setup_prefix` uses cross-boss' `cb-bootstrap` to set up the prefix environment.
   Bootstrapping must be fully integrated with the Flatcar SDK before prefix builds are considered stable.
2. Integrate prefix builds with `/build/<board>` environment and use board cross toolchain.
   Prefix builds currently use the SDK cross toolchains (`/usr/<arch>-gnu/`) instead of board toolchains in `/build/<board>`.
   Prefix builds must be integrated with the board toolchains and stop using `cb-emerge` before considered stable.
3. Add prefix wrappers for all portage tools (similar to board wrappers), not just `emerge`.
4. Add test cases for prefix builds to [mantle/kola](https://github.com/flatcar/mantle/tree/flatcar-master/kola).

## About

Prefix builds let you build and ship applications and all their dependencies in a custom directory.
This custom directory is self-contained, all dependencies are included, and binaries are only linked against libraries in the custom directory.
The applications' root will be `/` - i.e. there's no need to `chroot` into the custom directory.

For example, applications built with the prefix `/usr/local/my-app` will ship
* binaries in `/usr/local/my-app/bin`, `/usr/local/my-app/usr/bin`
* libraries in `/usr/local/my-app/lib[64]`, `/usr/local/my-app/usr/lib[64]`

These binaries can be called directly, e.g. `/usr/local/my-app/usr/bin/myprog`.
`myprog` will only use libraries from `/usr/local/my-app/lib` etc., not from `/`.

A good use case example for prefix builds is to create distro independent, portable [system extensions](https://www.flatcar.org/docs/latest/provisioning/sysext/).

## How does it do that?

Prefix uses a _staging environment_ to build binary packages, then installs these to a _final environment_.
The _staging environment_ contains toolchains and all build tools required to create binary packages (a full `@system`).
The _final environment_ only contains run-time dependencies.

Packages are built from ebuilds in coreos-overlay, portage-stable, and prefix-overlay.

A QoL `emerge` wrapper is included to install packages to the prefix.

## Prerequisites

Prefix utilises the [cross-boss](https://github.com/chewi/cross-boss) project to bootstrap prefixes and to build packages.
For the time being the user is expected to provide cross-boss manually.
By default, a `cross-boss` sub-directory is expected in the scripts repository root.
Cross-boss location can be customised via the `--cross_boss_root` option to `setup_prefix`.

* Run `git clone https://github.com/chewi/cross-boss` in the scripts directory.

## Quick-start guide

For working with a prefix, you will need to agree on:
1. A name for the prefix. Should be a single word and is used for generating protage wrappers.
2. A prefix directory where applications and libraries will live on the target system.
   For use with systemd-sysext this should be a path below `/usr` or `/opt`.

For the purpose of the example below we'll use
* `my-prefix` as the prefix name, and
* `/usr/local/my-stuff` as prefix directory.

**TL;DR**
* `./setup_prefix my-prefix /usr/local/my-stuff`
* `emerge-prefix-my-stuff-amd64-usr python`
will create a portable python installation in `__prefix__/amd64-usr/my-stuff/root`.


**Step by step**

First we'll create the prefix.
This will create "staging" and "final" roots and cross-compile a staging environment into "staging".
* In the SDK container, run `./setup_prefix my-prefix /usr/local/my-stuff`
* Go fetch a coffee, bootstrapping may take some 20-ish minutes to complete.

`setup_prefix` will default to `amd64-usr` architecture and will use
* `/build/prefix-<arch>/my-stuff` for the staging environment
* `__prefix__/<arch>/my-stuff` in the scripts directory as install root (aka "final")
* It will also create an emerge wrapper `emerge-prefix-my-stuff-<arch>` to install packages.

Time to use the wrapper! Let's build a portable python sysext.
* `emerge-prefix-my-stuff-amd64-usr python`

Now we'll use [bake.sh](https://raw.githubusercontent.com/flatcar/sysext-bakery/main/bake.sh) from Flatcar's [sysext-bakery](https://github.com/flatcar/sysext-bakery) to create a python sysext.
```shell
wget https://raw.githubusercontent.com/flatcar/sysext-bakery/main/bake.sh
chmod 755 bake.sh
cd __prefix__/amd64-usr/my-stuff
sudo cp -R root python
sudo ../../../bake.sh python
```

On a Flatcar instance, we now copy the resulting `python.raw` to `/etc/extensions`.
We merge with `systemd-sysext refresh`.
Then we can run:
* `/usr/local/my-stuff/usr/bin/python`

Note that this sysext can be used on any Linux distro that ships `systemd-sysext`.
It is self-contained, there are no user space dependencies.
