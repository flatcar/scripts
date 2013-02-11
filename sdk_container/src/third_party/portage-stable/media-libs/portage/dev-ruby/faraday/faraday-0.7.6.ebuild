# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/faraday/faraday-0.7.6.ebuild,v 1.1 2012/04/08 06:12:54 graaff Exp $

EAPI="2"

USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_TASK_TEST="test"
RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_EXTRADOC="README.md"

inherit ruby-fakegem eutils

DESCRIPTION="HTTP/REST API client library with pluggable components"
HOMEPAGE="http://github.com/technoweenie/faraday"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

ruby_add_rdepend ">=dev-ruby/rack-1.1.0
	>=dev-ruby/addressable-2.2.6
	>=dev-ruby/multipart-post-1.1.3"
ruby_add_bdepend "test? ( >=dev-ruby/test-unit-2.4 >=dev-ruby/webmock-1.7 )"

all_ruby_prepare() {
	# Remove bundler support.
	rm Gemfile || die
	sed -i -e '/[Bb]undler/d' test/helper.rb config.ru || die
}
