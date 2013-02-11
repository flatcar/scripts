# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/activeldap/activeldap-3.1.1-r1.ebuild,v 1.2 2012/08/16 15:20:40 flameeyes Exp $

EAPI=4
USE_RUBY="ruby18 ruby19"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.textile TODO"
RUBY_FAKEGEM_EXTRAINSTALL="po"

inherit ruby-fakegem

MY_P="${P/ruby-/}"
DESCRIPTION="Ruby/ActiveLDAP provides an activerecord inspired object oriented interface to LDAP"
HOMEPAGE="https://github.com/activeldap/activeldap"

LICENSE="GPL-2"
SLOT="3"
KEYWORDS="~amd64"
IUSE=""

# Most tests require a live LDAP server to run.
RESTRICT="test"

ruby_add_bdepend "dev-ruby/hoe"

ruby_add_rdepend "
	>=dev-ruby/activemodel-3.1.0
	dev-ruby/locale
	dev-ruby/fast_gettext
	dev-ruby/gettext_i18n_rails
	|| ( >=dev-ruby/ruby-ldap-0.8.2 dev-ruby/ruby-net-ldap )"

all_ruby_prepare() {
	# Comment out Gettext setup because it does not work with fast_gettext. This
	# patch probably breaks ruby_gettext usage. See
	# https://github.com/activeldap/activeldap/issues/33
	sed -i -e '/GetText\./ s:^:#:' lib/active_ldap/get_text_support.rb || die

	# Also allow Rails 3.2. Upstream has not released a version yet that is
	# 100% compatible, but it works for the most part and it is better than no
	# activeldap at all.
	sed -i -e '31d' -e 's/version: 3.1.0/version: "3.1"/' ../metadata || die
}

all_ruby_install() {
	all_fakegem_install

	dodoc doc/text/*

	insinto /usr/share/doc/${PF}
	doins -r examples
}
