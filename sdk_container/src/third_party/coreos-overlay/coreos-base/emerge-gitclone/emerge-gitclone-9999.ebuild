# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGIT_REPO_URI="https://github.com/flatcar/flatcar-dev-util.git"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
else
	#EGIT_COMMIT="00396595376d8d6a3c4b9251ba94e9de2d7a9e39" # flatcar-master
	EGIT_COMMIT="cd1b814127e8d8dbe8513ba10195eab70c853579" # flatcar-master
	EGIT_BRANCH="jepio/fetch-head"
	KEYWORDS="amd64 arm arm64 x86"
fi

PYTHON_COMPAT=( python3_{6..11} )

inherit git-r3 python-single-r1

DESCRIPTION="emerge utilities for Flatcar developer images"
HOMEPAGE="https://github.com/flatcar/flatcar-dev-util/"

LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

RDEPEND="sys-apps/portage"

src_compile() {
	echo "Nothing to compile"
}

src_install() {
	python_doscript emerge-gitclone
}
