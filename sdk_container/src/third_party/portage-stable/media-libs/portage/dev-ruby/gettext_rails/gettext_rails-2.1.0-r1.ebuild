# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/gettext_rails/gettext_rails-2.1.0-r1.ebuild,v 1.4 2012/02/06 17:34:49 ranger Exp $

EAPI=2
USE_RUBY="ruby18"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="ChangeLog README.rdoc"

RUBY_FAKEGEM_EXTRAINSTALL="data po"

inherit ruby-fakegem

DESCRIPTION="An L10 library for Ruby on Rails."
HOMEPAGE="http://www.yotabanana.com/hiki/ruby-gettext-rails.html"
LICENSE="Ruby"

KEYWORDS="amd64 ppc x86 ~x86-macos"
SLOT="0"
IUSE=""

# Tests are broken right now. Restrict them for now since we did not
# run them at all before.
RESTRICT="test"

ruby_add_rdepend "
	>=dev-ruby/gettext_activerecord-2.1.0
	>=dev-ruby/locale_rails-2.0.5
	>=dev-ruby/rails-2.3.2"

all_ruby_prepare() {
	# Avoid allison even when installed because it causes sandbox violations.
	sed -i -e 's/`allison --path`/""/' Rakefile || die
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}
	doins -r sample
}
