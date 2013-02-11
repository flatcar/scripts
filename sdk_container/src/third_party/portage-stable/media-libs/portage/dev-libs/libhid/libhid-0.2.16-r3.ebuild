# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libhid/libhid-0.2.16-r3.ebuild,v 1.4 2012/12/17 20:56:20 ago Exp $

EAPI="2"

PYTHON_DEPEND="python? 2"

inherit autotools python

DESCRIPTION="Provides a generic and flexible way to access and interact with USB HID devices"
HOMEPAGE="http://libhid.alioth.debian.org/"
SRC_URI="http://beta.magicaltux.net/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
IUSE="debug doc python"

RDEPEND="virtual/libusb:0"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	python? ( dev-lang/swig )"

pkg_setup() {
	python_set_active_version 2
}

src_prepare() {
	# Respect LDFLAGS
	export OS_LDFLAGS="${LDFLAGS}"
	# Bug #260884
	sed -i -e 's/-Werror//' m4/md_conf_compiler.m4 || die
	eautoconf
}

src_configure() {
	local myconf

	myconf="${myconf} $(use_with doc doxygen)"
	myconf="${myconf} $(use_enable debug)"
	myconf="${myconf} $(use_enable python swig)"

	if use python; then
		# libhid includes its own python detection m4 from
		# http://autoconf-archive.cryp.to/ac_python_devel.html
		# As it seems to detect python in the wrong place, we'll force it by
		# passing the right environnement variables, only if we have the python
		# flag
		PYTHON_LDFLAGS="$(python-config --ldflags)" econf ${myconf} || die
	else
		# avoid libhid running swig if it finds it automatically as long as the
		# "python" use flag is not set
		econf ${myconf} || die
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die "install failed"

	dodoc AUTHORS ChangeLog NEWS README README.licence TODO || die
	if use doc; then
		dohtml -r doc/html/* || die
	fi
	#delete .la file. Bug #313841
	rm "${D}"/$(python_get_sitedir)/${PN}/_hid.la

}
