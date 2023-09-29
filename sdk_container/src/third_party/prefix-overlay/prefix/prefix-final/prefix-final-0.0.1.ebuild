# Copyright (c) 2032 the Flatcar maintainers.
# Distributed under the terms of the Apache 2.0 license.

EAPI=7

DESCRIPTION="Prefix final layer base dependencies"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"

# These should be the absolute minimum runtime dependencies of the "final" prefix.
# "Staging" has @system so it is pretty heavyweight.
RDEPEND="
    virtual/libc
"
