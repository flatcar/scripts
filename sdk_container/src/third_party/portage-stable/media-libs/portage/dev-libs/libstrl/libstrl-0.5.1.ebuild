# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libstrl/libstrl-0.5.1.ebuild,v 1.4 2012/01/14 14:55:15 mgorny Exp $

EAPI=4

inherit autotools-utils multilib

DESCRIPTION="Compat library for functions like strlcpy(), strlcat(), strnlen(), getline(), and asprintf()"
HOMEPAGE="http://ohnopub.net/~ohnobinki/libstrl/"
SRC_URI="ftp://mirror.ohnopub.net/mirror/${P}.tar.bz2"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="amd64 x86 ~amd64-linux ~x64-macos"
IUSE="doc static-libs test"

DEPEND="doc? ( app-doc/doxygen )
	test? ( dev-libs/check )"
RDEPEND=""

src_configure() {
	local myeconfargs=(
		$(use_with doc doxygen)
		$(use_with test check)
	)

	autotools-utils_src_configure
}
