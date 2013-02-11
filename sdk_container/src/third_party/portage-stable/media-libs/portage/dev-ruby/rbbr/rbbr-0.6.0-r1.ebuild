# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rbbr/rbbr-0.6.0-r1.ebuild,v 1.2 2012/05/01 18:24:04 armin76 Exp $

EAPI="2"

# ruby-gtk2 has only ruby18
USE_RUBY="ruby18"

inherit ruby-ng

MY_P="${P}-withapi"
DESCRIPTION="Ruby Browser for modules/classes hierarchy and their constants and methods"
HOMEPAGE="http://ruby-gnome2.sourceforge.jp/hiki.cgi?rbbr"
SRC_URI="mirror://sourceforge/ruby-gnome2/${MY_P}.tar.gz"

KEYWORDS="~amd64 ~ppc ~x86"
SLOT="0"
LICENSE="Ruby"
IUSE="nls cjk"

ruby_add_rdepend ">=dev-ruby/ruby-gtk2-0.9.1"
ruby_add_rdepend nls ">=dev-ruby/ruby-gettext-0.5.5"
ruby_add_rdepend cjk ">=dev-ruby/refe-0.8.0"

S="${WORKDIR}/${MY_P}"

all_ruby_prepare() {
	# bug #59125
	rm lib/rbbr/doc/ri2.rb || die "failed to remove ri2.rb"
}

each_ruby_configure() {
	${RUBY} install.rb config || die "install.rb config failed"
}

each_ruby_compile() {
	${RUBY} install.rb setup || die "install.rb setup failed"
}

each_ruby_install() {
	${RUBY} install.rb install --prefix="${D}" || die "install.rb install failed"
}
