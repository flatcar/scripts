# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/dee/dee-1.0.14.ebuild,v 1.8 2013/02/02 22:24:27 ago Exp $

EAPI=4

AUTOTOOLS_AUTORECONF=y

inherit autotools-utils

DESCRIPTION="Provide objects allowing to create Model-View-Controller type programs across DBus"
HOMEPAGE="https://launchpad.net/dee/"
SRC_URI="https://launchpad.net/dee/1.0/${PV}/+download/${P}.tar.gz"

SLOT="0"
LICENSE="GPL-3"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86"
IUSE="doc debug examples +icu static-libs test"

RDEPEND="
	dev-libs/glib:2
	dev-libs/icu"
DEPEND="${RDEPEND}
	doc? ( dev-util/gtk-doc )
	test? (
		dev-libs/gtx
		dev-util/dbus-test-runner
		)"

src_prepare() {
	sed \
		-e '/GCC_FLAGS/s:-g::' \
		-e 's:vapigen:vapigen-0.14:g' \
		-i configure.ac || die
	echo true > py-compile || die
	autotools-utils_src_prepare
}

src_configure() {
	local myeconfargs=(
		--disable-silent-rules
		$(use_enable debug trace-log)
		$(use_enable test tests)
#		$(use_enable test extended-tests)
		$(use_enable icu)
		$(use_enable doc gtk-doc)
		)
	autotools-utils_src_configure
}

src_install() {
	autotools-utils_src_install

	if use examples; then
		insinto /usr/share/doc/${PN}/
		doins -r examples
	fi
}
