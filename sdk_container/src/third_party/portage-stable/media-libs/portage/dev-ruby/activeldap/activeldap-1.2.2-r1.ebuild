# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/activeldap/activeldap-1.2.2-r1.ebuild,v 1.3 2012/08/16 15:21:29 flameeyes Exp $

EAPI="2"
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC="docs"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="CHANGES README TODO"
RUBY_FAKEGEM_EXTRAINSTALL="data po rails rails_generators"

inherit ruby-fakegem

DESCRIPTION="Ruby/ActiveLDAP provides an activerecord inspired object oriented interface to LDAP"
HOMEPAGE="http://ruby-activeldap.rubyforge.org/doc/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86 ~x86-macos"
IUSE=""

# Most tests require a live LDAP server to run.
RESTRICT="test"

ruby_add_bdepend "
	doc? ( dev-ruby/hoe )
	test? (
		dev-ruby/hoe
		dev-ruby/test-unit:2
	)"

ruby_add_rdepend "
	=dev-ruby/activerecord-2.3*
	~dev-ruby/locale-2.0.5
	=dev-ruby/ruby-gettext-2.1.0*
	=dev-ruby/gettext_activerecord-2.1.0*
	>=dev-ruby/ruby-ldap-0.8.2"

all_ruby_prepare() {
	# Make activeldap more lenient towards newer Rails versions.
	sed -i -e "s/= 2.3.8/~>2.3.5/" lib/active_ldap.rb || die
	# And use our own stub metadata to avoid problems there as well.
	rm ../metadata || die
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}
	doins -r examples
}
