# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/httpclient/httpclient-2.2.5.ebuild,v 1.4 2013/01/15 07:07:45 zerochaos Exp $

EAPI=4

USE_RUBY="ruby18 ree18 ruby19 jruby"

RUBY_FAKEGEM_TASK_TEST="-Ilib test"
RUBY_FAKEGEM_TASK_DOC="doc"

RUBY_FAKEGEM_DOCDIR="doc"

RUBY_FAKEGEM_EXTRADOC="README.txt"

inherit ruby-fakegem

DESCRIPTION="'httpclient' gives something like the functionality of libwww-perl (LWP) in Ruby"
HOMEPAGE="https://github.com/nahi/httpclient"
SRC_URI="https://github.com/nahi/httpclient/tarball/v${PV} -> ${P}.tgz"
RUBY_S="nahi-httpclient-*"

LICENSE="Ruby"
SLOT="0"

KEYWORDS="amd64 ~arm ~ppc ~ppc64 x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

RDEPEND="${RDEPEND}
	!dev-ruby/http-access2"

ruby_add_rdepend "virtual/ruby-ssl"

ruby_add_bdepend "doc? ( dev-ruby/rdoc )"

all_ruby_prepare () {
	rm Gemfile || die
	sed -i -e '/[bB]undler/s:^:#:' Rakefile || die

	# Remove mandatory CI reports since we don't need this for testing.
	sed -i -e '/reporter/s:^:#:' Rakefile || die

	# Remove mandatory simplecov dependency
	sed -i -e '/[Ss]imple[Cc]ov/ s:^:#:' test/helper.rb || die

	# Comment out test requiring network access that makes assumptions
	# about the environment, bug 395155
	sed -i -e '/test_async_error/,/^  end/ s:^:#:' test/test_httpclient.rb || die
}

each_ruby_test() {
	${RUBY} -Ilib -S testrb test/test_*.rb || die
}
