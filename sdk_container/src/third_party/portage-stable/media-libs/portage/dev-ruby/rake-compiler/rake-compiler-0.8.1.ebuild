# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rake-compiler/rake-compiler-0.8.1.ebuild,v 1.11 2013/01/15 05:24:38 zerochaos Exp $

EAPI=4
USE_RUBY="ruby18 ree18 ruby19 jruby"

# Tests for now seem only to work when rubygems is fully installed for
# the implementation and that for now only means Ruby 1.8
RUBY_FAKEGEM_TASK_TEST="-f tasks/rspec.rake -f tasks/cucumber.rake spec cucumber"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="History.txt README.rdoc"

inherit ruby-fakegem eutils

DESCRIPTION="Provide a standard and simplified way to build and package Ruby extensions"
HOMEPAGE="http://github.com/luislavena/rake-compiler"
LICENSE="MIT"

SRC_URI="http://github.com/luislavena/${PN}/tarball/v${PV} -> ${P}.tar.gz"
RUBY_S="luislavena-${PN}-*"

KEYWORDS="alpha amd64 ~arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
SLOT="0"
IUSE=""

# Restrict tests for this version so that we have a version to bootstrap
# ruby19 stable.
RESTRICT="test"
# USE_RUBY="ruby18 ree18" \
# 	ruby_add_bdepend "test? ( dev-util/cucumber )"

# ruby_add_bdepend "test? ( dev-ruby/rspec:2 dev-ruby/rubygems )"
ruby_add_rdepend "dev-ruby/rake"

each_ruby_prepare() {
	case ${RUBY} in
		*ruby19|*jruby)
			# Remove this task so that it won't load on Ruby 1.9 and JRuby
			# that lack the package_task file. It is, though, needed for the
			# tests
			rm tasks/gem.rake || die
			# Remove specs aimed at a C-compiling ruby implementation.
			rm spec/lib/rake/extensiontask_spec.rb || die
			;;
		*)
			;;
	esac
}

each_ruby_test() {
	case ${RUBY} in
		*ruby19)
			${RUBY} -S rspec spec || die "Tests failed."
			;;
		*jruby)
			${RUBY} -S rspec spec || die "Tests failed."
			;;
		*)
			each_fakegem_test
			;;
	esac
}
