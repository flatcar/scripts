# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rspec-core/rspec-core-2.10.1.ebuild,v 1.5 2013/01/15 05:52:14 zerochaos Exp $

EAPI=4
USE_RUBY="ruby18 ree18 ruby19 jruby"

RUBY_FAKEGEM_TASK_TEST="none"
RUBY_FAKEGEM_TASK_DOC="none"

RUBY_FAKEGEM_EXTRADOC="Changelog.md README.md"

# Also install this custom path since internal paths depend on it.
RUBY_FAKEGEM_EXTRAINSTALL="exe"

RUBY_FAKEGEM_GEMSPEC="rspec-core.gemspec"

inherit ruby-fakegem

DESCRIPTION="A Behaviour Driven Development (BDD) framework for Ruby"
HOMEPAGE="http://rspec.rubyforge.org/"
SRC_URI="https://github.com/rspec/${PN}/tarball/v${PV} -> ${P}-git.tgz"
RUBY_S="rspec-${PN}-*"

LICENSE="MIT"
SLOT="2"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RDEPEND="${RDEPEND} !<dev-ruby/rspec-1.3.1-r1"

ruby_add_bdepend "test? (
		dev-ruby/nokogiri
		dev-ruby/syntax
		>=dev-ruby/fakefs-0.4.0
		>=dev-ruby/zentest-4.4.1
		dev-ruby/rspec-expectations:2
		dev-ruby/rspec-mocks:2
	)"
ruby_add_bdepend "doc? ( dev-ruby/yard )"

#	>=dev-ruby/cucumber-0.5.3
#	>=dev-ruby/autotest-4.2.9 -> zentest-4.4.1
#	dev-ruby/aruba"

all_ruby_prepare() {
	# Don't set up bundler: it doesn't understand our setup.
	sed -i -e '/[Bb]undler/d' Rakefile || die

	# Remove the Gemfile to avoid running through 'bundle exec'
#	rm Gemfile || die

	# Also clean the /usr/lib/rubyee path (which is our own invention).
	sed -i -e 's#lib\\d\*\\/ruby\\/#lib\\d*\\/ruby(ee|)\\/#' lib/rspec/core/configuration.rb || die

	# Remove jruby-specific comparison documents since for us the normal
	# version passes.
	cp spec/rspec/core/formatters/text_mate_formatted-1.8.7.html spec/rspec/core/formatters/text_mate_formatted-1.8.7-jruby.html|| die

	# Duplicate exe also in bin. We can't change it since internal stuff
	# also depends on this and fixing that is going to be fragile. This
	# way we can at least install proper bin scripts.
	cp -R exe bin || die

	# Avoid unneeded dependency on git.
	sed -i -e '/git ls-files/ s:^:#:' rspec-core.gemspec || die
}

each_ruby_prepare() {
	case ${RUBY} in
		*jruby)
			# We don't have aruba for jruby support yet.
			sed -i -e '/aruba/ s:^:#:' -e '74,76 s:^:#:' spec/spec_helper.rb || die
			rm spec/command_line/order_spec.rb || die
			;;
		*)
			;;
	esac
}

all_ruby_compile() {
	if use doc ; then
		yardoc || die
	fi
}

each_ruby_test() {
	case ${RUBY} in
		*jruby)
			# Run jruby's tests with the installed rspec script since
			# otherwise files can't be found for some unknown reason.
			RUBYLIB=${S}/lib ${RUBY} -S rspec --color spec || die "Tests failed."
			;;
		*)
			PATH="${S}/bin:${PATH}" RUBYLIB="${S}/lib" ${RUBY} -S rake spec || die "Tests failed."
			;;
	esac

	# There are features but it seems as if these only work against a
	# fully installed version.
}
