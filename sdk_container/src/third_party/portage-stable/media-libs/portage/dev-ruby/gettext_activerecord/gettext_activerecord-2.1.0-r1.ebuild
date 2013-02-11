# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/gettext_activerecord/gettext_activerecord-2.1.0-r1.ebuild,v 1.7 2012/05/01 18:24:13 armin76 Exp $

EAPI="2"
USE_RUBY="ruby18"

RUBY_FAKEGEM_EXTRADOC="ChangeLog README.rdoc"
RUBY_FAKEGEM_EXTRAINSTALL="data po"

inherit ruby-fakegem

DESCRIPTION="An L10 library for ActiveRecord."
HOMEPAGE="http://www.yotabanana.com/hiki/ruby-gettext-rails.html"
LICENSE="Ruby"

KEYWORDS="amd64 ppc x86 ~x86-macos"
SLOT="0"
IUSE=""

ruby_add_rdepend ">=dev-ruby/ruby-gettext-2.1.0
	>=dev-ruby/activerecord-2.3.2"

ruby_add_bdepend "test? ( virtual/ruby-test-unit !dev-ruby/test-unit:2 )"

all_ruby_prepare() {
	strip-linguas -u po
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}
	doins -r sample
}
