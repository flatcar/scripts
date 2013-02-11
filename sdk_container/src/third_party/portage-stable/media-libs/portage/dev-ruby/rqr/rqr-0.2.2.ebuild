# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rqr/rqr-0.2.2.ebuild,v 1.2 2011/09/18 12:21:51 flameeyes Exp $

EAPI=4

# ruby19 → uses old RString interface
# jruby → native extension, unusable
USE_RUBY="ruby18 ree18"

# do not use Rake tasks for this as it requires hoe, newgem, and is
# generally a mess.
RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="README.txt History.txt"

inherit ruby-fakegem flag-o-matic

DESCRIPTION="A ruby library to create qrcode"
HOMEPAGE="http://rqr.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="doc test +jpeg +png +tiff"

ruby_add_bdepend "doc? ( virtual/ruby-rdoc )
	test? ( virtual/ruby-test-unit )"

CDEPEND="jpeg? ( virtual/jpeg )
	png? ( media-libs/libpng )
	tiff? ( media-libs/tiff )"

RDEPEND="${RDEPEND} ${CDEPEND}"
DEPEND="${DEPEND} ${CDEPEND}"

# tests require the presence of all external formats; simply add them as
# a requirement for now.
REQUIRED_USE="test? ( jpeg png tiff )"

RUBY_PATCHES=( "${FILESDIR}"/${P}+libpng-1.5.patch )

each_ruby_configure() {
	cd ext/rqr
	${RUBY} extconf.rb || die "extconf.rb failed"
}

each_ruby_compile() {
	# this should be handled by extconf.rb, but unfortunately it mangles
	# the CFLAGS rather than doing it properly so we have to replicate
	# it here until upstream makes a sense out of it.
	#
	# Note: you can avoid using any of those, but then it would only
	# generate EPS, which might or might not be what you want.
	use jpeg && append-flags -DUSE_JPG
	use png && append-flags -DUSE_PNG
	use tiff && append-flags -DUSE_TIFF

	# extension uses C++, so use CXXFLAGS not CFLAGS
	emake -C ext/rqr \
		CFLAGS="${CXXFLAGS} -fPIC" archflag="${LDFLAGS}" || die "emake failed"
	cp ext/rqr/QR.so lib/rqr || die
}

all_ruby_compile() {
	if use doc; then
		${RUBY} rdoc || die "rdoc failed"
	fi
}

each_ruby_test() {
	${RUBY} -Ilib test/test_rqr.rb || die "tests failed"
}
