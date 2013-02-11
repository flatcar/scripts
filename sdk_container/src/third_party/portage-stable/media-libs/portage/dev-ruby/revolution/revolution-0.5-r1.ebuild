# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/revolution/revolution-0.5-r1.ebuild,v 1.3 2011/08/21 03:32:22 phajdan.jr Exp $

EAPI="2"
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_TASK_TEST=""

inherit ruby-fakegem

DESCRIPTION="Ruby binding for the Evolution email client."
HOMEPAGE="http://revolution.rubyforge.org/"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE=""

DEPEND=">=gnome-extra/evolution-data-server-1.12"
RDEPEND="${DEPEND}"

each_ruby_configure() {
	${RUBY} extconf.rb
}

each_ruby_compile() {
	emake
}

each_ruby_install() {
	ruby_fakegem_doins revolution.so
}
