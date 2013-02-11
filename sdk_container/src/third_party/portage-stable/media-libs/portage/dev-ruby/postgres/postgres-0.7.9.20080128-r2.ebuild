# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/postgres/postgres-0.7.9.20080128-r2.ebuild,v 1.2 2012/08/16 16:56:49 flameeyes Exp $

EAPI=2
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="Contributors README"

# changes 0.7.1.20060406 to 0.7.1.2006.04.06

# ideally, PV would have been this to start with, but can't change it now as
# 0.7.1.20051221 > 0.7.1.2006.04.06.
RUBY_FAKEGEM_VERSION="0.7.9.2008.01.28"

inherit multilib ruby-fakegem versionator

MY_P="${RUBY_FAKEGEM_NAME}-${RUBY_FAKEGEM_VERSION}"

DESCRIPTION="An extension library to access a PostgreSQL database from Ruby"
HOMEPAGE="http://ruby.scripting.ca/postgres"
SRC_URI="mirror://rubygems/${MY_P}.gem"
LICENSE="GPL-2 Ruby"
SLOT="0"
KEYWORDS="amd64 hppa ppc ppc64 x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE=""

RDEPEND="${RDEPEND} dev-db/postgresql-base"
DEPEND="${DEPEND} dev-db/postgresql-base"

all_ruby_prepare() {
	# Remove yaml metadata so we supply our own gemspec. There are no
	# ruby dependencies and this might fix bug 407829.
	rm ../metadata || die
}

each_ruby_configure() {
	${RUBY} -Cext extconf.rb || die
}

each_ruby_compile() {
	emake -Cext || die
}

each_ruby_install() {
	mkdir lib || die
	mv ext/postgres$(get_modname) lib/ || die

	each_fakegem_install
}
