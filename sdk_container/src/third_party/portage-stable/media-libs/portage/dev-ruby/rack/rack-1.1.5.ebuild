# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rack/rack-1.1.5.ebuild,v 1.6 2013/01/21 14:09:52 ago Exp $

EAPI=4
USE_RUBY="ruby18 ree18 jruby"

RUBY_FAKEGEM_DOCDIR="doc"

RUBY_FAKEGEM_BINWRAP=""

inherit ruby-fakegem eutils

DESCRIPTION="A modular Ruby webserver interface"
HOMEPAGE="http://rubyforge.org/projects/rack"
SRC_URI="mirror://rubyforge/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~arm ppc ppc64 x86 ~x86-fbsd ~amd64-linux ~ia64-linux ~x86-linux ~x86-macos ~x64-solaris ~x86-solaris"
IUSE=""

# The gem has automagic dependencies over mongrel, ruby-openid,
# memcache-client, thin, mongrel and camping; not sure if we should
# make them dependencies at all.
ruby_add_bdepend "test? ( dev-ruby/test-spec )"

all_ruby_prepare() {
	# Avoid tests depending on now randomized hash ordering.
	sed -i -e '/foobarfoo/ s:^:#:' test/spec_rack_response.rb || die
	sed -i -e '/should build query strings correctly/,/end/ s:^:#:' test/spec_rack_utils.rb || die
	sed -i -e '/should build nested query strings correctly/,/end/ s:^:#:' test/spec_rack_utils.rb || die
}

each_ruby_prepare() {
	case ${RUBY} in
		*jruby)
			# Avoid broken specs. Already broken in 1.1.3 and not likely
			# to be fixed anymore due to the age of this version.
			rm test/spec_rack_mock.rb test/spec_rack_runtime.rb || die
			;;
		*)
			;;
	esac
}

each_ruby_test() {
	# Since the Rakefile calls specrb directly rather than loading it, we
	# cannot use it to launch the tests or only the currently-selected
	# RUBY interpreter will be tested.
	${RUBY} -S specrb -Ilib:test -w -a \
		-t '^(?!Rack::Handler|Rack::Adapter|Rack::Session::Memcache|rackup)' \
		|| die "test failed for ${RUBY}"
}
