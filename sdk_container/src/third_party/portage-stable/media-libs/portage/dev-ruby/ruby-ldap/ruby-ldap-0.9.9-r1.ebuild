# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-ldap/ruby-ldap-0.9.9-r1.ebuild,v 1.7 2011/10/09 17:22:37 xarthisius Exp $

EAPI="2"
USE_RUBY="ruby18"

inherit ruby-ng

DESCRIPTION="A Ruby interface to some LDAP libraries"
HOMEPAGE="http://code.google.com/p/ruby-activeldap/"
SRC_URI="http://ruby-activeldap.googlecode.com/files/${P}.tar.bz2"
LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ~ppc64 sparc x86 ~x86-macos"
IUSE="ssl"
DEPEND=">=net-nds/openldap-2
	ssl? ( dev-libs/openssl )"
RDEPEND="${DEPEND}"

# Current test set is interactive due to certificate generation and requires
# running LDAP daemon
RESTRICT="test"

each_ruby_configure() {
	${RUBY} extconf.rb --with-openldap2 || die "extconf.rb failed"
}

each_ruby_compile() {
	emake || die
}

each_ruby_install() {
	emake DESTDIR="${D}" install || die
	dodoc ChangeLog FAQ README TODO
}
