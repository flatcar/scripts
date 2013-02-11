# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/faraday/faraday-0.8.1.ebuild,v 1.1 2012/07/05 23:43:13 flameeyes Exp $

EAPI=4

USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_TEST="test"
RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_EXTRADOC="README.md"

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

inherit ruby-fakegem eutils

DESCRIPTION="HTTP/REST API client library with pluggable components"
HOMEPAGE="http://github.com/technoweenie/faraday"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

ruby_add_rdepend ">=dev-ruby/multipart-post-1.1.3"
USE_RUBY="ruby18 ree18" ruby_add_rdepend "dev-ruby/system_timer"
ruby_add_bdepend "test? (
		>=dev-ruby/test-unit-2.4
		>=dev-ruby/webmock-1.7
		dev-ruby/sinatra
	)"

all_ruby_prepare() {
	# Remove bundler support.
	rm Gemfile || die
	sed -i -e '/[Bb]undler/d' test/helper.rb config.ru || die
}

each_ruby_prepare() {
	case "${RUBY}" in
		*/ruby18|*/ree18)
			# add a dependency on system_timer for Ruby 1.8 as upstream suggests for
			# proper timeouts
			sed -i -e '/^end/i s.add_dependency "system_timer"' ${RUBY_FAKEGEM_GEMSPEC} || die
			;;
	esac
}
