# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/sqlite-ruby/sqlite-ruby-2.2.3-r2.ebuild,v 1.10 2012/07/01 18:31:41 armin76 Exp $

EAPI="2"
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README"

inherit ruby-fakegem

DESCRIPTION="An extension library to access a SQLite database from Ruby"
HOMEPAGE="http://rubyforge.org/projects/sqlite-ruby/"
LICENSE="BSD"

KEYWORDS="amd64 hppa ~mips ppc ppc64 x86 ~x86-fbsd"
SLOT="0"
IUSE=""

DEPEND="${DEPEND}
	=dev-db/sqlite-2*"

RDEPEND="${RDEPEND}
	=dev-db/sqlite-2*"

each_ruby_configure() {
	${RUBY} -Cext extconf.rb || die "Configuration failed."
}

each_ruby_compile() {
	emake -Cext || die "Compilation failed."
	cp ext/sqlite_api.so lib || die "Unable to cp shared library."
}

each_ruby_test() {
	${RUBY} test/tests.rb || die "Tests failed."
}

all_ruby_install() {
	all_fakegem_install

	dohtml -r doc/faq
}
