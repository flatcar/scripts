# Overview

This overlay contains Flatcar-specific packages and Gentoo packages that differ
from their upstream Gentoo versions.

See the upstream [gentoo](https://github.com/gentoo/gentoo) repo for packages
that do not have Flatcar-specific changes.

Licensing information can be found in the respective files, so consult
them directly. Most ebuilds are licensed under the GPL version 2.

# Important packages

`coreos-base/coreos` is the package responsible for everything that gets
built into a production image and is not OEM specific.

`coreos-base/coreos-dev` is the package responsible for everything that
gets built into a developer image and is not OEM specific.

`coreos-devel/sdk-depends` is the package responsible for everything that
gets built into the Container Linux SDK.

`coreos-devel/board-packages` is everything that could be built into a
development or production image.

`coreos-base/oem-*` are the OEM specific packages. They mostly install things
that belong in the OEM partition.
