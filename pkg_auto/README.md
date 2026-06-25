# A guide for handling package updates

## Initial setup

We will need three checkouts of the scripts repo. I recommend using git worktrees (`git help worktree`) to save yourself from cloning the repo three times and then syncing them. The checkouts are:

- A base for worktrees created by the package automation. It should be set to a branch that will serve as the "before the package updates" branch (which usually is `main`).

- A checkout set to the "after the package updates" branch (usually something like `buildbot/weekly-portage-stable-package-updates-2026-05-25`).
  - I actually use `krnowak/weekly` branch which is based on the buildbot branch. I do it because it is less typing. But then I also need to remember to sync my branch and the buildbot branch before asking for review.

- A checkout set to the `krnowak/pkg-auto-commits` branch - the scripts in `main` are outdated.

Another checkout thay may come in handy while working on the package updates is the Gentoo repository.

## Assumptions and variables used later

Let's assume that a path to the scripts repo with the "before the package updates" branch is stored in the `SCRIPTS` variable, a path to the scripts repo with "after the package updates" branch checked out is stored in the `UPDATED_SCRIPTS` variable, and a path to the scripts repo with package automation scripts - in `PKG_AUTO`.

Also let's assume that a branch name with "before the package updates" state (as said before, usually it's `main`) is stored in variable `BEFORE`, while a branch name with "after the package updates" state is stored in `AFTER`. And let's assume that `AFTER` branch is based on `BEFORE`.

Finally, let's assume that the `GENTOO` variable contains a path to the local checkout of Gentoo.

## Before generating reports

It is a good idea to check the annotations on GitHub Action workflow page of the run that generated the "after the package updates" branch. Sometimes packages get removed from Gentoo and this will result in a warning printed in the annotations. The runs can be found in ["Keep portage-stable packages updated" workflow](https://github.com/flatcar/scripts/actions/workflows/update-portage-stable-packages-from-list.yaml). Such packages should either be dropped from package automation list and either dropped from portage-stable or moved to coreos-overlay.

The package automation list is in `.github/workflows/portage-stable-packages-list`.

## Generating reports

The happy path where everything goes perfectly well looks more or less like this:

1. We create a directory for the weekly reports, like `weekly-reports` and make it our working directory:
   - `mkdir weekly-reports && cd weekly-reports`
2. We download the needed SDK image and listings:
   - Make sure that the `BEFORE` branch is checked out in `SCRIPTS`.
   - `"${PKG_AUTO}/pkg_auto/download_sdk_and_listings.sh" -s "${SCRIPTS}" -x aux-cleanups aux`
   - This downloads an SDK with a version taken from the `version.txt` manifest in the `SCRIPTS` repo.
   - `aux-cleanups` is a file that can be later sourced to cleanup the downloaded Docker images and files.
     - Don't do it now, but when you are done with package updates, then call `source aux-cleanups`.
   - `aux` is where the downloads will be put.
3. Create a config file that will tell the automation about the scripts repo, the `BEFORE` and `AFTER` branches, where the reports should be stored, where are the listings, etc. The contents should be as follows:

        scripts: ${SCRIPTS}
        aux: aux
        reports: reports
        old-base: ${BEFORE}
        new-base: ${AFTER}
        cleanups: file,wd-cleanups

   You could also create the above config file by invoking yet another script:
     - `"${PKG_AUTO}/pkg_auto/generate_config.sh" -a aux -n "${AFTER}" -o "${BEFORE}" -r reports -s "${SCRIPTS}" -x file,wd-cleanups config`
4. Generate the reports:
   - `"${PKG_AUTO}/pkg_auto/generate_reports.sh" -w wd config`
   - This will create a directory `wd` with some stuff the automation needs, `wd-cleanups` file that can be sourced later to clean up things in `wd`, and `reports` with the, well, reports.
5. Work through the reports, described below in [What do to before processing?](#what-do-to-before-processing).

## Issues with report generation

- SDK failed to download.
  - This shouldn't happen. In the past this could have happened when a nightly build failed to build SDK after updating the `version.txt` manifest and pushing a new tag. The solution was to use some earlier nightly version as `BEFORE` and rebase `AFTER` on top of `BEFORE`. But currently the CI should revert the changes if nightly SDK failed to build, thus `version.txt` should point to a version with an existing SDK.
- Reports could not be generated. This will be accompanied by the output from emerge printed into your screen. Ignore warnings about `cross-${ARCH}-cros-linux-gnu/${PKG}` not being merged, because they are in `package.provided` - the automation adds those packages into the file on purpose. The typical reasons behind a report generation failure are:
  - Missing eclass - some updated package started using eclass that we haven't yet imported into portage-stable. See [Importing stuff from Gentoo](#importing-stuff-from-gentoo) below.
  - Missing dependency - some updated package started using a package that we haven't yet imported into portage-stable. See [Importing stuff from Gentoo](#importing-stuff-from-gentoo) below.
    - Note that this sometimes has a tendency of spiraling into importing a whole bunch of dependencies. Oftentimes this can be limited by disabling some USE flag for the package. Please use your judgement when determining if the dependencies should be pulled or not.
  - All versions of the package are masked - this may happen when we used to use an unstable version of a package (which means that there is an entry in `profiles/coreos/base/package.accept_keywords` file in coreos overlay), and that version is gone after the update, usually because some newer version or revision landed. In such cases, update the entry in `package.accept_keywords`.

After addressing issues raised by the automation, cleanup the automation's working directory (`source wd-cleanups`), remove the reports directory and rerun the reports generation again.

## Importing stuff from Gentoo

This is a matter of copying a package from Gentoo into portage-stable, commiting it, and adding an entry to the package automation list. There is a script that automates the first two steps:

- `cd "${UPDATED_SCRIPTS}/sdk_container/src/third_party/portage-stable"`
- `"${PKG_AUTO}/pkg_auto/impl/sync_with_gentoo.sh" "${GENTOO}" eclass/stuff.eclass foo-bar/quux one-two/three`

When adding entries to the package automation list, please keep the list sorted.

### Special cases

- selinux

    - There is a special case - adding selinux policy package (`sec-policy/selinux-foo`). Most (all?) of the `sec-policy/selinux-` packages come from the same tarball, which we are patching. To ensure that the policies are consistent, we need to make sure that all the selinux policy packages are patched. This is done by adding a symlink - you can see this done for other policy packages in `coreos/user-patches/sec-policy` in coreos-overlay.


- acct-{user,group}

For certain package categories there are additional steps/checks needed:

- When adding a package from `acct-user` or `acct-group` category to Flatcar:
  - If the added user/group is a part of our `passwd`/`group` file from baselayout (see https://github.com/flatcar/baselayout/tree/flatcar-master/share/baselayout), you need to make sure that the numerical IDs are consistent. If not, they need to be overridden in `make.defaults` of the `generic` profile (see `profiles/coreos/targets/generic/make.defaults` in coreos-overlay for prior art).
  - If the added user/group is not a part of our `passwd`/`group` files, you still need to check if the IDs are not conflicting. If they are, then the same override needs to be added.

## What is in the generated reports?

Before we talk about processing the updates, it is probably a good idea to describe what we are really working with. The above steps generated a bunch of directories and files inside the `reports` directory. The directory is structured as follows:

### `reports-from-sdk` directory

Contains outputs generated by emerge for the SCRIPTS repo (in `old` subdirectory) and for the UPDATED_SCRIPTS repo (in `new` subdirectory). I found it useful if I wanted to check, for example, which USE flags some package has enabled or disabled.

Inside the `old` and `new` subdirectories, there are following files (for SOMETHING being `sdk`, `amd64-board`, `arm64-board`):
- `${SOMETHING}-emerge-output`, `${SOMETHING}-emerge-output-filtered`, `${SOMETHING}-emerge-output-junk`, `${SOMETHING}-emerge-output-warnings`
  - The first file contains the standard output of emerge, the last one contains its standard error.
  - The `filtered` and `junk` files are based on the emerge-output file - the former contains useful package information, the latter just extra stuff that emerge tends to throw into the screen.
- `${ARCH}-board-bdeps`
  - This is a list of packages that are build dependencies of board packages.
  - These packages should be in SDK. This file is not yet used by anything, but the idea was to have a check that makes sure that all the build dependencies are in SDK, so they will not be build again and again every time we build a production image.
- `${SOMETHING}-package-repos`
  - A list of package name and its repository name.
- `${SOMETHING}-pkgs`
  - A list of packages, their versions and slots.
- `${SOMETHING}-pkgs-kv`
  - Same as above but also comes with key-value pairs for `LLVM_SLOTS`, `PYTHON_TARGETS` and the like.
  - I think those key-value pairs are `USE_EXPAND` flags.
- `${SOMETHING}-profiles`
  - A list of Gentoo profiles used, in an inheritance order. The bottom profiles override things from top profiles.
- `${REPO}-cache`
  - The md5 cache generated for portage-stable and coreos-overlay.

### `updates` directory

Contains summary and changelog stubs and reports for the changed packages.

- `summary_stubs` is what eventually ends up being pasted into the GitHub PR with the package updates for the reviewer.
  - The entry in this file looks like:

      ```
      - PACKAGE_NAME: [WHERE] [WHERE] …
        - still at VERSION (or from OLD_VERSION to NEW_VERSION)
        - stuff generated by the automation (about keywords, USE flags or dependencies)
        - TODO: review ebuild.diff
        - TODO: review other.diff
        - TODO: review occurences
      ```

  - `WHERE` describes whether it is a part of the main image (PROD), developer container (DEV), some sysext (for example SYSEXT-PODMAN, SYSEXT-CONTAINERD) or OEM sysext (AZURE, VMWARE).
- `changelog_stubs` is what eventually ends up commited to UPDATED_SCRIPTS as an entry in the `changelog/updates` directory.
- `eclass`:
  - Contains directories named after the changed eclass. Inside there is only `eclass.diff`. There isn't anything else, since each eclass is self-contained single file.
- `licenses`:
  - Contains diffs about license texts. This directory only has two files: `brief-summary` and `modified.diff`. The former is a short description of licenses added, removed or modified, the latter is the full diff.
  - The contents of the `brief-summary` are more-or-less copy-pasted by automation into the summary stubs.
  - I honestly have never used these files. Whatever ends up in summary stubs is good enough already.
- `profiles`:
  - Contains diff for the files in profiles. Contains the following files:
    - `relevant.diff` - a diff of files relevant to Flatcar. This is the primary file to check when processing profiles.
    - `full.diff` - just a full recursive diff of the whole profiles directory. Annoying to work with, I seldom (if ever) used it.
    - `possibly-irrelevant-files` - a list of files from `full.diff` that did not end up in `relevant.diff`. It is sometimes good to quickly check the list of automation mistakes.
- The rest of the things are `category/package` directories of modified packages. Each such directory contains:
  - `brief-summary`:
    - Describes which files were modified.
    - I honestly never used that. Probably unnecessary, so I think it should be dropped.
  - `full.diff`:
    - What it says - a diff representing everything that has changed in the directory.
    - Never used this one either…
  - `occurences`
    - A report of the package name appearing in various locations of the scripts repository.
    - The locations are:
      - overlay profiles
      - portage-stable profiles
      - config overrides (`coreos/config/env`)
      - user patches (`coreos/user-patches`)
      - overlay (outside profiles)
      - portage-stable (outside profiles)
      - the rest of the scripts repo
  - `other.diff`:
    - Diffs of package metadata and files in package's `files` directory (patches, configs)
  - Directories named after a package slot:
    - Usually named just `0` (zero), as most packages have a slot 0.
    - Sometimes named `${OLD_SLOT}-to-${NEW_SLOT}`.
    - Sometimes there can be more than one directory, if we have multiple version of the package installed.
    - The directory contains only `ebuild.diff`, which shows the differences between the ebuilds used in SCRIPTS and UPDATED_SCRIPTS.

### `used-licenses`

A list of all licenses used by Flatcar packages. I think that it is mostly package automation that usesthis file to filter out all the unused license texts from a commit that synces the `licenses` directory.

### `warnings`

A list of warnings that should be addressed. These are mostly things like inconsistent versions between amd64 and arm64 boards.

### `manual-work-needed`

A list of items that the automation did not know how to handle.

## What do to before processing?

1. Check the `warnings` reports:
   - These usually can be handled by adding/updating accept keyword entries in base profile.
   - There may be warnings about packages existing only in old or new state.
     - If the package exists only in the old state, this may mean that some package stopped being used, so maybe it could be dropped from Flatcar.
     - If the package exists only in the new state, you probably just added a package to Flatcar. This is expected.
   - Handling issues in this file may cause also issues from `manual-work-needed` file to be resolved as well.

2. Check the `manual-work-needed` reports:
   - These show up in scenarios where multiple slots (thus multiple versions) of a package are installed in the old state, and the new state had some slot changes that the automation cannot reconcile.
   - There are tools that may help you with handling the package manually:
     - `PKG_AUTO/pkg_auto/occurences.sh`:
       - Prints occurences of the package in the scripts repository - same thing as the occurences file in the reports.
       - Example: `"${PKG_AUTO}/pkg_auto/occurences.sh" "${UPDATED_SCRIPTS}" sys-devel/gcc`
     - `PKG_AUTO/pkg_auto/diff_pkg.sh`:
       - Prints either an ebuild diff or other diff.
       - Examples:
         - `"${PKG_AUTO}/pkg_auto/diff_pkg.sh" e "${SCRIPTS}" "${UPDATED_SCRIPTS}" sys-devel/gcc 14.1.0 15.1.0` for printing ebuild diff
         - `"${PKG_AUTO}/pkg_auto/diff_pkg.sh" o "${SCRIPTS}" "${UPDATED_SCRIPTS}" sys-devel/gcc` for printing diffs of metadata, patch files, etc.

3. Check the `summary_stubs` file if some package got downgraded:
   - Just search for `downgrade` in there.
   - This may happen when an unstable ebuild we were using disappeared after update, so emerge fell back to an older, but stable ebuild. Possibly just accept keywords update is in order here.

4.  Open GitHub issues listing for current advisories:
   - https://github.com/flatcar/Flatcar/issues?q=is%3Aissue%20state%3Aopen%20label%3Aadvisory
   - If there is more than one page of issues, good idea might be to open all the pages in separate tabs.
   - Go over the list of packages there to kinda-sorta remember what is in there.

## Actual processing

I usually have an editor open with a split view. On left pane I have `summary_stubs` open at all times. The right pane is for viewing the occurences, diffs and whatnot. I usually have a second editor window open to edit files in profiles (like `package.accept_keywords`, `package.mask`, etc.).

### Relevancy to Flatcar

When processing a package, make sure that the changes you describe are relevant to Flatcar. Relevant things may be:
- Package version update (note that the revision bump does not necessarily means that there is a change relevant for Flatcar).
- Package got stable/unstable. The automation already adds that to the report.
- EAPI changed.
- Changes in USE flags. Covered by automation, but may need more explanation about the changed USE flag.
- Cross-compilation fixes.
- Dependency changes, partially covered by automation.

If there are no changes relevant for Flatcar then the entry for the package could be dropped from the summary. It can often be helpful to refer to Gentoo git log to understand the changes and to decide if they are relevant.


### EAPI

Usually an EAPI update seems to be rather inconsequential. Although when this happens it is good to check at config overrides in the occurences to see if our modifications and hooks could be affected by some behavior change due to the EAPI bump. Documentation for EAPI can be found on [Gentoo wiki](https://wiki.gentoo.org/wiki/Project:Package_Manager_Specification).

### USE flags

When a USE flag is removed from the package, it is good to check in occurences file if we should remove mentions of the now-obsolete flag from our overlay profiles.

When a USE flag is added, you can use `${SOMETHING}-pkgs-kv` in the `reports-from-sdk/new` to see the status of the USE flag in the package in Flatcar. This can help you to make a decision whether the USE flag should be disabled or enabled in Flatcar.

### Dependencies

These are generally handled by the automation, but since the automation is still quite dumb, some postprocessing may be still required:

- There are several kinds of dependencies - runtime dependencies (`RDEPEND`), dependencies (`DEPEND`), build dependencies (`BDEPEND`). Very often ebuilds specify one set of dependencies in terms of another (like `DEPEND="${RDEPEND}"`), so a change in one set causes a change in another. The automation will then duplicate the entries, so it may be useful to deduplicate that.
- Sometimes dependency changes are listed by the automation, but there are no associated diffs in the ebuild - this means that the dependency changes came through some eclass. I think such changes can be dropped from the summary stubs - these are mostly noise anyway. Examples of such situations:
  - A package adds a support for signature verification of the source tarballs, so it inherits the `verify-sig` eclass, which results in entries like "added a dependency '…' for USE 'verify-sig?'".
  - A package is patching its autotools-based build system, thus it requires the build system to be regenerated. In order to so so it inherits the `autotools` eclass, which results in pulling in dependencies on `dev-build/autoconf`, `dev-build/automake`, `app-portage/elt-patches`, `dev-build/libtool` and so on.
  - The `autoconf.eclass` gets updated - its `_LATEST_AUTOCONF` or `_LATEST_AUTOMAKE` variable gets updated, and this change gets propagated to literally hundreds of packages, which is a lot of noise to remove.

### Release notes

  - Grep for already existing changelog entries in the script repo - the results may give you a clue where the release notes are.
  - Sometimes unfortunately the release notes are in form of an entry in the mailing list with a non-obvious link. Checking the old entries may give you a clue what to search for. Some projects use topics like "ANNOUNCEMENT: <PROJECT> <VERSION>", others use "<PROJECT> <VERSION> released!" and so on - this may make it easier to google for release notes of a new version.
  - I usually try to give links to release notes of all of the intermediate versions in case a version bump spans several releases, but sometimes there span of intermediate releases is like 20 versions, so cutting the list short may be in order (like ignoring patch releases of older minor releases). For SDK-only packages, I only put the latest release - it most likely won't be a part of the final changelog anyway.
  - Skimming through release notes can be a useful practice for spotting if there were some security issues fixed - these ought to be mentioned in the summary explicitly.

### CVEs

  - If a package update fixes a CVE (either because a new version is used, or Gentoo added/backported a patch), I add an entry to the summary like:

        ```
        - fixes CVE-<NUMBERS>, CVE-<NUMBERS>, …
          - <LINK TO THE ADVISORY ISSUE IN FLATCAR>
        ```

  - If the update does not address all the CVEs in the GitHub issue, I usually add `(partially)` next to the link. Later, when updating the pull request message I can add `Closes #<ISSUE NUMBER>` or `Partially addresses #<ISSUE NUMBER>`.
- Eclasses:
  - I usually refer to the git log of the Gentoo repository to understand the changes made in the eclass. Very often they are not really relevant to Flatcar, so maybe the entry for the eclass could be dropped from the summary. Relevant changes are mostly the same as for ebuilds - dependency changes, EAPI support, cross-compilation fixes, etc.  But things like better support for Ada in toolchain.eclass is something we can omit.

### Profiles

  - This mostly involves going over the `relevant.diff` file and trying to spot anything that could affect Flatcar. This requires a familiarity with what packages are in Flatcar.
  - From time to time support for a new Python version gets added (or dropped for some old version). When this happens, Python stuff in `make.defaults` in overlay profiles should be updated (in both `profiles/coreos/targets/sdk/transition` and `profiles/coreos/base`). This means PYTHON_SINGLE_TARGET, PYTHON_TARGETS and BOOTSTRAP_USE.

## After processing

- Filling changelog stubs:
  - The package automation writes stubs for all the packages that received an update. For starters, most of the SDK-only packages should likely be dropped from the changelog. But not all - things like dev-lang/go should stay, since they affect production images.
  - Usually the entry format is "where: what ([version](link-to-release-notes))", but in case of intermediate versions I usually do "where: what ([version](link-to-release-notes) (includes [intermediate-version1](link-to-intermediate1-release-notes), …))". See existing changelog entries for examples.
  - When all TODOs are addressed, then this file could be saved in `changelog/updates` directory in `UPDATED_SCRIPTS`.
- Security changelog:
  - There is no stub generated by automation for the security changelog, so it needs to be written from scratch. As always, there is plenty of examples in the `changelog/security` directory.
  - Searching for "CVE" in summary stubs should let you easily spot what packages should be mentioned here.
- Update the buildbot branch and kick of the CI.
  - Remember to use two-phase SDK build, especially when packages like catalyst or portage got updated.

If fixing a CI failure means rebuilding some package, please be aware that some board packages are built during the sdk-container job and the later stage jobs just reuse the binary packages. In such situation rerunning the package-all-arches job won't fix the issue.

## After the PR is merged

- aux-cleanups, wd-cleanups
- update partially addressed security issues

# TODO

- fewer bullet points, more paragraphs
- user-patches regeneration on package update
  - there should always be a readme next to the patches that describes what they do, if and when they could be dropped and if some special steps are required to generate patches (looking at you, selinux policies)
- nvidia-drivers, old-nvidia-drivers and nvidia-drivers-service
  - until we have a mechanism that moves flatcar users from old version of nvidia sysext to a different one, we need to handle a situation where a version used for sysext is removed from Gentoo
    - in this case, the ebuild and associated files should be copied from x11-drivers/nvidia-drivers in portage-stable to x11-drivers/old-nvidia-drivers in coreos-overlay
  - whenever nvidia-drivers gets a bump, check if x11-drivers/nvidia-drivers-service in coreos-overlay should receive the same bump
