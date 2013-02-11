# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/qrosspython/qrosspython-9999.ebuild,v 1.1 2011/08/22 17:51:37 maksbotan Exp $

EAPI=3

EGIT_REPO_URI="git://github.com/0xd34df00d/Qross.git"
EGIT_PROJECT="qross-${PV}"
PYTHON_DEPEND="2"

inherit python cmake-utils git-2

DESCRIPTION="Python scripting backend for Qross."
HOMEPAGE="http://github.com/0xd34df00d/Qross"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="debug"

DEPEND="=dev-libs/qrosscore-${PV}"
RDEPEND="${DEPEND}"

CMAKE_USE_DIR="${S}/src/bindings/python/qrosspython"
