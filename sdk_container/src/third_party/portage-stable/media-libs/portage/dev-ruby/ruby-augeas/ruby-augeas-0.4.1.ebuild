# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-augeas/ruby-augeas-0.4.1.ebuild,v 1.9 2012/12/30 14:06:40 ago Exp $

EAPI=3
# jruby -> native extentions
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_DOCDIR="doc/site/api"
RUBY_FAKEGEM_EXTRADOC="NEWS README.rdoc"

inherit multilib ruby-fakegem

DESCRIPTION="Ruby bindings for Augeas"
HOMEPAGE="http://augeas.net/"
SRC_URI="http://augeas.net/download/ruby/${P}.gem"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ~hppa ia64 ppc sparc x86"
IUSE=""

DEPEND="${DEPEND} >=app-admin/augeas-0.5.1 dev-libs/libxml2"
RDEPEND="${RDEPEND} >=app-admin/augeas-0.5.1"

RUBY_PATCHES=( ${P}-libxml2.patch )

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
