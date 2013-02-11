# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-augeas/ruby-augeas-0.3.0-r1.ebuild,v 1.8 2013/02/03 12:27:01 pacho Exp $

EAPI=2
USE_RUBY="ruby18"

RUBY_FAKEGEM_DOCDIR="doc/site/api"
RUBY_FAKEGEM_EXTRADOC="NEWS README.rdoc"

inherit multilib ruby-fakegem

DESCRIPTION="Ruby bindings for Augeas"
HOMEPAGE="http://augeas.net/"
SRC_URI="http://augeas.net/download/ruby/${P}.gem"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="hppa"
IUSE=""

DEPEND="${DEPEND} >=app-admin/augeas-0.5.1 <app-admin/augeas-0.10"
RDEPEND="${RDEPEND} >=app-admin/augeas-0.5.1"

each_ruby_configure() {
	${RUBY} -Cext/augeas extconf.rb || die
}

each_ruby_compile() {
	emake -Cext/augeas || die
}

each_ruby_install() {
	mv ext/augeas/_augeas$(get_modname) lib/ || die

	each_fakegem_install
}
