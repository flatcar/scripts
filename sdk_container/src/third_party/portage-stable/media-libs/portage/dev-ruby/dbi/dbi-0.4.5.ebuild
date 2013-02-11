# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/dbi/dbi-0.4.5.ebuild,v 1.1 2012/09/02 13:28:06 flameeyes Exp $

EAPI=4
USE_RUBY="ruby18"

RUBY_FAKEGEM_RECIPE_TEST="none"
RUBY_FAKEGEM_RECIPE_DOC="rdoc"

RUBY_FAKEGEM_BINWRAP=""

RUBY_FAKEGEM_EXTRADOC="README ChangeLog"

inherit ruby-fakegem

DESCRIPTION="Database independent interface for accessing databases"
HOMEPAGE="http://ruby-dbi.rubyforge.org/"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="odbc postgres mysql sqlite sqlite3 test"

ruby_add_bdepend "test? ( >=dev-ruby/test-unit-2.5.1-r1 )"
ruby_add_rdepend "dev-ruby/deprecated:2"

PDEPEND="
	mysql?    ( dev-ruby/dbd-mysql )
	postgres? ( dev-ruby/dbd-pg )
	odbc?     ( dev-ruby/dbd-odbc )
	sqlite?   ( dev-ruby/dbd-sqlite )
	sqlite3?  ( dev-ruby/dbd-sqlite3 )"

RUBY_PATCHES=( ${P}-gentoo.patch )

each_ruby_test() {
	ruby-ng_testrb-2 -Ilib test/ts_dbi.rb
}

pkg_postinst() {
	if ! (use mysql || use postgres || use odbc || use sqlite || use sqlite3)
	then
		elog "${P} now comes with external database drivers."
		elog "Be sure to set the right USE flags for ${PN} or emerge the drivers manually:"
		elog "They are called dev-ruby/dbd-{mysql,odbc,pg,sqlite,sqlite3}"
	fi
}
