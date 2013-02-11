# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/eina/eina-1.7.4.ebuild,v 1.1 2012/12/21 19:27:50 tommy Exp $

EAPI="2"

inherit enlightenment

DESCRIPTION="Enlightenment's data types library (List, hash, etc) in C"

SRC_URI="http://download.enlightenment.org/releases/${P}.tar.bz2"
LICENSE="LGPL-2.1"

KEYWORDS="~amd64 ~arm ~x86"
IUSE="altivec debug default-mempool mempool-buddy +mempool-chained
	mempool-fixed-bitmap +mempool-pass-through
	mmx sse sse2 static-libs test"

RDEPEND="debug? ( dev-util/valgrind )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	test? (
		dev-libs/check
		dev-libs/glib
		dev-util/lcov
	)"

src_configure() {
	local MODULE_ARGUMENT="static"
	if use debug ; then
		MODULE_ARGUMENT="yes"
	fi

	# Evas benchmark is broken!
	MY_ECONF="
	$(use_enable altivec cpu-altivec)
	$(use_enable !debug amalgamation)
	$(use_enable debug stringshare-usage)
	$(use_enable debug assert)
	$(use_enable debug valgrind)
	$(use debug || echo " --with-internal-maximum-log-level=2")
	$(use_enable default-mempool)
	$(use_enable doc)
	$(use_enable mempool-buddy mempool-buddy $MODULE_ARGUMENT)
	$(use_enable mempool-chained mempool-chained-pool $MODULE_ARGUMENT)
	$(use_enable mempool-fixed-bitmap mempool-fixed-bitmap $MODULE_ARGUMENT)
	$(use_enable mempool-pass-through mempool-pass-through $MODULE_ARGUMENT)
	$(use_enable mmx cpu-mmx)
	$(use_enable sse cpu-sse)
	$(use_enable sse2 cpu-sse2)
	$(use test && echo " --disable-amalgamation")
	$(use_enable test e17)
	$(use_enable test tests)
	$(use_enable test benchmark)
	$(use test && echo " --with-internal-maximum-log-level=6")
	--enable-magic-debug
	--enable-safety-checks
	"

	enlightenment_src_configure
}
