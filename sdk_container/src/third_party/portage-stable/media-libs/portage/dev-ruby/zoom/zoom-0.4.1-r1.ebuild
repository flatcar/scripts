# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/zoom/zoom-0.4.1-r1.ebuild,v 1.2 2012/08/16 15:16:57 flameeyes Exp $

EAPI=4
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_DOCDIR="html"
RUBY_FAKEGEM_EXTRADOC="ChangeLog README"

inherit multilib ruby-fakegem

IUSE=""

DESCRIPTION="A Ruby binding to the Z39.50 Object-Orientation Model (ZOOM)"
HOMEPAGE="http://ruby-zoom.rubyforge.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"

DEPEND+=" dev-libs/yaz"
RDEPEND+=" dev-libs/yaz"

ruby_add_bdepend "test? ( virtual/ruby-test-unit )"

each_ruby_configure() {
	${RUBY} -Csrc extconf.rb || die
}

each_ruby_compile() {
	emake -Csrc
}

each_ruby_install() {
	mkdir lib || die
	cp src/zoom$(get_modname) lib/ || die

	each_fakegem_install
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}
	doins -r sample
}
