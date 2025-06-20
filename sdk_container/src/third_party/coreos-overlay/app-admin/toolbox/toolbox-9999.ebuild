# Copyright (c) 2014 CoreOS, Inc.. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGIT_REPO_URI="https://github.com/flatcar/toolbox.git"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm64"
else
	EGIT_COMMIT="2fae95b467d6961a396b88d6aa20a9d6bee943c6" # main
	KEYWORDS="amd64 arm64"
fi

inherit git-r3

DESCRIPTION="toolbox"
HOMEPAGE="https://github.com/flatcar/toolbox"
SRC_URI=""

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

src_install() {
	dobin ${S}/toolbox
}
