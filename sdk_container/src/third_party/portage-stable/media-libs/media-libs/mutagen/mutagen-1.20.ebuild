# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/mutagen/mutagen-1.20.ebuild,v 1.7 2011/04/24 17:42:45 armin76 Exp $

EAPI=3

PYTHON_DEPEND="2"
SUPPORT_PYTHON_ABIS="1"
DISTUTILS_SRC_TEST="setup.py"

inherit distutils

DESCRIPTION="Mutagen is an audio metadata tag reader and writer implemented in pure Python."
HOMEPAGE="http://code.google.com/p/mutagen http://pypi.python.org/pypi/mutagen"
SRC_URI="http://${PN}.googlecode.com/files/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 hppa ~ia64 ppc ppc64 sparc x86 ~x86-interix ~amd64-linux ~x86-linux"
IUSE="test"

RDEPEND=""
DEPEND="test? (	dev-python/eyeD3
			dev-python/pyvorbis
			media-libs/flac[ogg]
			media-sound/vorbis-tools )"
RESTRICT_PYTHON_ABIS="3.*"

DOCS="API-NOTES NEWS README TODO TUTORIAL"
