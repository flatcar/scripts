# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/pg/pg-0.11.0.ebuild,v 1.9 2012/05/01 18:24:04 armin76 Exp $

EAPI=2
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_TEST_TASK=""

RUBY_FAKEGEM_TASK_DOC="apidocs"
RUBY_FAKEGEM_DOCDIR="docs/api"
RUBY_FAKEGEM_EXTRADOC="ChangeLog Contributors README"

inherit ruby-fakegem

DESCRIPTION="Ruby extension library providing an API to PostgreSQL"
HOMEPAGE="http://bitbucket.org/ged/ruby-pg/"

LICENSE="|| ( GPL-2 Ruby )"
SLOT="0"
KEYWORDS="amd64 ~hppa ppc ppc64 x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE=""

RDEPEND="${RDEPEND}
	dev-db/postgresql-base"
DEPEND="${DEPEND}
	dev-db/postgresql-base
	test? ( dev-db/postgresql-server )"

ruby_add_bdepend "
	doc? (
		dev-ruby/rake-compiler
		|| ( >=dev-ruby/yard-0.6.1 dev-ruby/rdoc ) )
	test? ( dev-ruby/rspec:2 )"

each_ruby_configure() {
	pushd ext
	${RUBY} extconf.rb || die "extconf.rb failed"
	popd
}

each_ruby_compile() {
	pushd ext
	emake CFLAGS="${CFLAGS} -fPIC" archflag="${LDFLAGS}" || die "emake failed"
	popd
	cp ext/*.so lib || die
}

each_ruby_test() {
	if [[ "${EUID}" -ne "0" ]]; then
		# Make the rspec call explicit, this way we don't have to depend
		# on rake-compiler (nor rubygems) _and_ we don't have to rebuild
		# the whole extension from scratch.
		${RUBY} -Ilib -S rspec -fs spec/*_spec.rb || die "spec failed"
	else
		ewarn "The userpriv feature must be enabled to run tests."
		eerror "Testsuite will not be run."
	fi
}
