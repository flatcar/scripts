# Overview

This overlay contains Container Linux specific packages and Gentoo packages
that differ from their upstream Gentoo versions.

See the [portage-stable](https://github.com/coreos/portage-stable) repo
for packages which do not have Container Linux specific changes.

Licensing information can be found in the respective files, so consult
them directly. Most ebuilds are licensed under the GPL version 2.

Upstream Gentoo sources: https://gitweb.gentoo.org/repo/gentoo.git

# Important packages

`coreos-base/coreos` is the package responsible for everything that gets
built into a production image and is not OEM specific.

`coreos-base/coreos-dev` is the package responsible for everything that
gets built into a developer image and is not OEM specific.

`coreos-devel/sdk-depends` is the package responsible for everything that
gets built into the Container Linux SDK.

`coreos-devel/board-packages` is everything that could be built into a
development or production image, plus any OEM specific packages.

`coreos-base/oem-*` are the OEM specific packages. They mostly install things
that belong in the OEM partition. Any RDEPENDS from these packages should
be copied to the RDEPENDS in `board-packages` to ensure they are built.

`coreos-base/coreos-oem-*` are metapackages for OEM specific ACIs. 

# Updating

To update follow the following steps:

* Remove or rename the whole folder of the package to prepare the import from
  upstream Gentoo, not only resetting the ebuild file but also any additional
  files like patches or downstream additions under `files`.
* Run `~/trunk/src/scripts/update_ebuilds --portage_stable . CATEGORY/PACKAGE`
  in the `coreos-overlay` folder to import a new version from upstream Gentoo.
  Drop the ebuild files that you don't plan to use.
* Commit the changes with a message like `CATEGORY/PACKAGE: Sync from Gentoo`,
  and mention the the commit ID in the body (`git show update_ebuilds/master`).
* Now find all downstream patches for the package by running
  `git log CATEGORY/PACKAGE`. If everybody followed the process of resetting
  before importing an upstream update, you only have to look for the commits
  after the last update and port them to the new version. Otherwise you have
  to compare the files manually to their upstream versions from older
  [portage](https://github.com/gentoo/portage/) revisions.
* You can combine all old and new downstream patches into a single new commit
  with the message `CATEGORY/PACKAGE: Apply Flatcar patches` to keep the number of
  commits to port low, or have separate commits. Make sure that you explain
  the changes and carry the explanations from old commits over, either in the
  commit message, through comments in the ebuild file, or through a `README.md`
  in the folder.
