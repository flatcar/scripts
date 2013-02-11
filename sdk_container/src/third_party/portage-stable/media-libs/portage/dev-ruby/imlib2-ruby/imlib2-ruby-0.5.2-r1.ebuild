# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/imlib2-ruby/imlib2-ruby-0.5.2-r1.ebuild,v 1.1 2010/06/25 21:43:52 graaff Exp $

EAPI=2
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="AUTHORS ChangeLog README TODO"

inherit multilib ruby-fakegem

DESCRIPTION="Imlib2 bindings for Ruby, written with the help of these people."
HOMEPAGE="http://www.pablotron.org/software/imlib2-ruby/"
SRC_URI="http://www.pablotron.org/files/gems/${P}.gem"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

DEPEND="${DEPEND} >=media-libs/imlib2-1.2.0"
RDEPEND="${RDEPEND} >=media-libs/imlib2-1.2.0"

each_ruby_configure() {
	${RUBY} extconf.rb || die
}

each_ruby_compile() {
	emake || die
}

each_ruby_install() {
	mkdir lib || die
	cp imlib2$(get_modname) lib/ || die

	each_fakegem_install
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}
	doins -r examples || die
}
