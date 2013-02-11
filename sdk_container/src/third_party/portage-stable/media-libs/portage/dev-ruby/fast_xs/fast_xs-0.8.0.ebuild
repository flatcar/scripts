# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/fast_xs/fast_xs-0.8.0.ebuild,v 1.13 2013/01/15 05:16:24 zerochaos Exp $

EAPI=4

USE_RUBY="ruby18 ree18 ruby19"

RUBY_FAKEGEM_TASK_DOC="docs"
RUBY_FAKEGEM_DOCDIR="doc"

RUBY_FAKEGEM_EXTRADOC="History.rdoc README.rdoc"

inherit ruby-fakegem

DESCRIPTION="fast_xs text escaping library ruby bindings."
HOMEPAGE="http://fast-xs.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc x86 ~x86-fbsd ~x86-solaris"
IUSE=""

ruby_add_bdepend "doc? ( >=dev-ruby/hoe-2.3.2 )"
ruby_add_bdepend "test? (
	>=dev-ruby/hoe-2.3.2
	virtual/ruby-test-unit
	dev-ruby/rack
)"

USE_RUBY="ruby18" ruby_add_bdepend "test? ( www-servers/mongrel )"

RUBY_PATCHES=( "${P}+ruby-1.9.patch" )

each_ruby_configure() {
	${RUBY} -Cext/fast_xs extconf.rb || die "extconf.rb failed"
	${RUBY} -Cext/fast_xs_extra extconf.rb || die "extconf.rb failed"
}

each_ruby_compile() {
	emake -Cext/fast_xs CFLAGS="${CFLAGS} -fPIC" archflag="${LDFLAGS}" || die "make extension failed"
	cp ext/fast_xs/fast_xs$(get_modname) lib/ || die
	emake -Cext/fast_xs_extra CFLAGS="${CFLAGS} -fPIC" archflag="${LDFLAGS}" || die "make extension failed"
	cp ext/fast_xs_extra/fast_xs_extra$(get_modname) lib/ || die
}

each_ruby_test() {
	# the Rakefile tries to run all the tests in a single process, but
	# this breaks the monkey-patchers, we're forced to run them one by
	# one.
	for tu in test/test_*.rb; do
		${RUBY} -Ilib $tu || die "test $tu failed"
	done
}
