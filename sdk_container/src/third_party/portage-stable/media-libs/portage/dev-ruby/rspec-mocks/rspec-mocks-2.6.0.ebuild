# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rspec-mocks/rspec-mocks-2.6.0.ebuild,v 1.12 2013/01/15 05:45:34 zerochaos Exp $

EAPI=2
USE_RUBY="ruby18 ree18 jruby"

RUBY_FAKEGEM_TASK_TEST="none"

RUBY_FAKEGEM_TASK_DOC="none"
RUBY_FAKEGEM_EXTRADOC="README.md"

inherit ruby-fakegem

DESCRIPTION="A Behaviour Driven Development (BDD) framework for Ruby"
HOMEPAGE="http://rspec.rubyforge.org/"

LICENSE="MIT"
SLOT="2"
KEYWORDS="alpha amd64 ~arm hppa ia64 ppc ppc64 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

# cucumber and rspec-core are loaded unconditionally in the Rakefile,
# so we also need to require them for USE=doc.
ruby_add_bdepend "test? (
		>=dev-ruby/rspec-core-2.6.0:2
		dev-ruby/rspec-expectations:2
	)
	doc? ( dev-ruby/rspec-core:2 )"

# Not clear yet to what extend we need those (now)
#	>=dev-ruby/cucumber-0.6.2
#	>=dev-ruby/aruba-0.1.1"

all_ruby_prepare() {
	# Don't set up bundler: it doesn't understand our setup.
	sed -i -e '/[Bb]undler/d' Rakefile || die

	# Remove the Gemfile to avoid running through 'bundle exec'
	rm Gemfile || die
}

all_ruby_compile() {
	if use doc ; then
		RUBYLIB="${S}/lib" rake rdoc || die
	fi
}

each_ruby_test() {
	case ${RUBY} in
		*jruby)
			# This particular failure is reported to be fixed in jruby 1.6.
			ewarn "Tests disabled because they crash jruby."
			;;
		*)
			PATH="${S}/bin:${PATH}" RUBYLIB="${S}/lib" ${RUBY} -S rake spec || die
			;;
	esac

	# There are features but they require aruba which we don't have yet.
}
