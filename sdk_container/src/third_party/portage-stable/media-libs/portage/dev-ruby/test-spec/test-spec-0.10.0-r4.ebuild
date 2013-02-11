# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/test-spec/test-spec-0.10.0-r4.ebuild,v 1.7 2013/01/16 01:01:24 zerochaos Exp $

EAPI="4"

USE_RUBY="ruby18 ree18 ruby19 jruby"

RUBY_FAKEGEM_EXTRADOC="README SPECS ROADMAP TODO"
RUBY_FAKEGEM_DOCDIR="doc"

inherit ruby-fakegem eutils

DESCRIPTION="A library to do Behavior Driven Development with Test::Unit"
HOMEPAGE="http://chneukirchen.org/blog/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~arm amd64 ~hppa ~ia64 ppc ppc64 ~sparc x86"
IUSE=""

ruby_add_rdepend virtual/ruby-test-unit
ruby_add_bdepend test dev-ruby/mocha

# On Ruby 1.9, the tests require test-unit as minitest is not enough
USE_RUBY=ruby19 \
	ruby_add_rdepend '>=dev-ruby/test-unit-2.0.6'

all_ruby_prepare() {
	epatch "${FILESDIR}"/${P}-jruby.patch
}

each_ruby_prepare() {
	if [[ ${RUBY} == */ruby19 ]]; then
		pushd .. >/dev/null
		epatch "${FILESDIR}"/${P}+ruby-19.patch
		popd >/dev/null
	fi
}

all_ruby_install() {
	all_fakegem_install

	docinto examples
	dodoc examples/* || die
}
