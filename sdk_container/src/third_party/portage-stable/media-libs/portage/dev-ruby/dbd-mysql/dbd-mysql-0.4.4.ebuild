# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/dbd-mysql/dbd-mysql-0.4.4.ebuild,v 1.7 2012/09/02 09:04:22 flameeyes Exp $

EAPI=2
USE_RUBY="ruby18"  # Upstream says mysql is not ruby19 ready yet (for 0.4.3)

inherit ruby-ng

DESCRIPTION="The MySQL database driver (DBD) for Ruby/DBI"
HOMEPAGE="http://ruby-dbi.rubyforge.org"
SRC_URI="mirror://rubyforge/ruby-dbi/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="test"

ruby_add_rdepend "
	>=dev-ruby/dbi-0.4.2
	>=dev-ruby/mysql-ruby-2.8_pre4"

src_test() {
	elog "The tests require additional configuration."
	elog "You will find them in /usr/share/${PN}/test/"
	elog "Be sure to read the file called DBD_TESTS."
}

each_ruby_configure() {
	${RUBY} setup.rb config --prefix=/usr
}

each_ruby_install() {
	${RUBY} setup.rb install \
		--prefix="${D}" || die "setup.rb install failed"
}

all_ruby_install() {
	dodoc ChangeLog README

	if use test; then
		dodir /usr/share/${PN}
		cp -pPR test "${D}/usr/share/${PN}" || die "couldn't copy tests"
	fi
}
