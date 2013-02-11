# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/configliere/configliere-0.4.18.ebuild,v 1.1 2012/12/16 09:34:08 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_RECIPE_TEST="rspec"
RUBY_FAKEGEM_RECIPE_DOC="rdoc"

RUBY_FAKEGEM_EXTRADOC="CHANGELOG.textile README.textile FEATURES.txt"

inherit ruby-fakegem

DESCRIPTION="Settings manager for Ruby scripts"
HOMEPAGE="https://github.com/infochimps-labs/configliere"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

ruby_add_rdepend "
	>=dev-ruby/highline-1.5.2
	>=dev-ruby/multi_json-1.1"

RUBY_PATCHES=( ${PN}-0.4.17-nobundler.patch )

all_ruby_prepare() {
	rm Gemfile* || die
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}
	doins -r examples
}
