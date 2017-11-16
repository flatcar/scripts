# Overview

This overlay contains curated unmodified Gentoo packages that are part
of the Container Linux build and are exact copies of upstream Gentoo packages.

# Updating packages

Use `src/scripts/update_ebuilds` to fetch the latest copy from Gentoo:

    cd ~/trunk/src/scripts
    repo start update-foo ../third-party/portage-stable
    ./update_ebuilds --commit app-fun/foo

Note: `update_ebuilds` can fetch from either Gentoo's Github mirror or
Rsync services.
If you'd prefer to use a local copy of the portage tree, you can point
`update_ebuilds` at a local filepath:

    rsync -rtlv rsync://rsync.gentoo.org/gentoo-portage ~/gentoo-portage
    ./update_ebuilds --commit --portage ~/gentoo-portage app-fun/foo

Licensing information can be found in the respective files, so consult
them directly. Most ebuilds are licensed under the GPL version 2.

Upstream Gentoo sources: http://sources.gentoo.org/gentoo-x86/

# Removing packages

Be careful when removing packages. The following section offers tips for preventing
breakage, but they are by no means exhaustive. Be especially careful with packages that
might affect `sys-devel/binutils`, `sys-devel/gcc`, `sys-kernel/linux-headers`, and
`sys-libs/glibc` (see `TOOLCHAIN_PKGS` in `scripts/build_library/toolchain_util.sh`).

## git log

`git log <category>/<package>` will show commits that touched that directory. These can give
clues about why a package was included in the first place and where to look to ensure it really
is unused.

## equery d

`equery d -a <package-name>` will tell you what packages depend on `package-name`. It will
also generate a lot of false positives, since it considers all dependencies for all use flags,
even ones we do not use, such as `test`.

## emerge --emptytree

`emerge --pretend --verbose --emptytree <package-name>` _should_ give a list of all the dependencies
for a given package. Use this to test if `board-packages`, `sdk-depends`, and `@system` can still be
emerged after removing an ebuild and package.
Remember to use the `emerge-<arch>-usr` commands to check `board-packages` and `emerge` to check
`sdk-depends`. Use both when checking `@system`.

Furthermore, the SDK bootstrapping process uses a list of packages defined the by SDK profile's packages.build
file. Install `dev-util/catalyst` and run `/usr/lib64/catalyst/targets/stage1/build.py` to get a list of packages
needed for the boostrapping process, then run `emerge --emptytree` on that list.

A package's ebuild must be removed from `portage-stable` _and_ the package must be removed locally. If only the
ebuild is removed, the package will be silently elided in the `emerge --emptytree` dependency list.
To see if there are any packages installed without ebuilds run `eix -tTc`. There are no `eix-<arch>-usr` wrappers, so double
check the packages are also unmerged via the `emerge-<arch>-usr` commands. Make sure to run
`eix-update` before running other `eix` commands.

`emerge --emptytree` also has unintuitive behavior when handling virtual packages.
When making changes affecting virtual packages (removing a provider, changing use flags that affect
a provider or virtual, etc), `emerge --emptytree` will always prefer an already installed
provider (unless it is masked or otherwise disabled), so unmerge the current provider before
running `emerge --emptytree` to ensure the virtuals are resolved correctly. Look at the virtual package's
ebuild to see what providers it has and use `emerge --search` to see what is the currently installed provider.
See [this bug](https://bugs.gentoo.org/127956).

## grep, git grep, repo grep, ripgrep, find, etc

Use your favorite grep variant to see if the package is used anywhere. Good places to double check are
coreos-overlay, manifest, scripts, and portage-stable, as well as anything specific to the package.

Be sure to check `coreos-overlay` to ensure there are no use flags, accept_keywords, or other leftover bits
relating to the package being removed.

## Updating the metadata cache

If you remove a package, make sure to delete the corresponding files in
metadata/md5cache, or run use egencache to do it for you:
```
    egencache --update --repo portage-stable
```
There is also `scripts/update_metadata` which will update both `portage-stable` and `coreos-overlay`
and optionally generate a commit message.

## Testing changes

If you have Jenkins running with [this configuration](https://github.com/coreos/jenkins-os), you can make pull requests with your changes and
test them according to the instructions in the [jenkins-os README](https://github.com/coreos/jenkins-os#usage-examples)
