# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/twitter/twitter-4.4.1.ebuild,v 1.1 2012/12/11 07:17:12 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_DOC="yard"
RUBY_FAKEGEM_EXTRADOC="CHANGELOG.md README.md"

inherit ruby-fakegem

DESCRIPTION="Ruby wrapper around the Twitter API"
HOMEPAGE="http://twitter.rubyforge.org/"

LICENSE="MIT"
SLOT="4"
KEYWORDS="~amd64 ~x86"
IUSE=""

ruby_add_rdepend "
	=dev-ruby/faraday-0*
	>=dev-ruby/faraday-0.8
	>=dev-ruby/multi_json-1.3
	=dev-ruby/multi_json-1*
	=dev-ruby/simple_oauth-0*
	>=dev-ruby/simple_oauth-0.2"

ruby_add_bdepend "test? (
	dev-ruby/rspec:2
	dev-ruby/webmock
	)
	doc? ( dev-ruby/yard )"

all_ruby_prepare() {
#	rm Gemfile || die
	sed -i -e '/[Bb]undler/d' Rakefile || die "Unable to remove bundler code."
}

each_ruby_test() {
	CI=true ${RUBY} -S rspec spec || die
}
