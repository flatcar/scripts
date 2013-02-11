# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/pg/pg-0.13.2.ebuild,v 1.3 2012/08/04 07:15:46 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ree18 ruby19"

RUBY_FAKEGEM_TEST_TASK=""

RUBY_FAKEGEM_TASK_DOC="redocs"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="ChangeLog Contributors.rdoc README.rdoc History.rdoc"

inherit ruby-fakegem

DESCRIPTION="Ruby extension library providing an API to PostgreSQL"
HOMEPAGE="http://bitbucket.org/ged/ruby-pg/"

LICENSE="|| ( GPL-2 Ruby )"
SLOT="0"
KEYWORDS="~amd64 ~hppa ~ppc ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RDEPEND="${RDEPEND}
	dev-db/postgresql-base"
DEPEND="${DEPEND}
	dev-db/postgresql-base
	test? ( dev-db/postgresql-server )"

ruby_add_bdepend "
	doc? (
		dev-ruby/hoe
		|| ( >=dev-ruby/yard-0.6.1 dev-ruby/rdoc ) )
	test? ( dev-ruby/rspec:2 )"

all_ruby_prepare() {
	# hack the Rakefile to make it sure that it doesn't load
	# rake-compiler (so that we don't have to depend on it and it
	# actually works when building with USE=doc).
	sed -i \
		-e '/Rakefile.cross/s:^:#:' \
		-e '/ExtensionTask/,/^end$/ s:^:#:' \
		Rakefile || die

	sed -i -e '18i require "socket"' spec/pg/connection_spec.rb || die
}

each_ruby_configure() {
	${RUBY} -C ext extconf.rb || die "extconf.rb failed"
}

each_ruby_compile() {
	emake -C ext CFLAGS="${CFLAGS} -fPIC" archflag="${LDFLAGS}"
	cp ext/*.so lib || die
}

each_ruby_test() {
	if [[ "${EUID}" -ne "0" ]]; then
		# Make the rspec call explicit, this way we don't have to depend
		# on rake-compiler (nor rubygems) _and_ we don't have to rebuild
		# the whole extension from scratch.
		${RUBY} -Ilib -S rspec -fs spec || die "spec failed"
	else
		ewarn "The userpriv feature must be enabled to run tests."
		eerror "Testsuite will not be run."
	fi
}
