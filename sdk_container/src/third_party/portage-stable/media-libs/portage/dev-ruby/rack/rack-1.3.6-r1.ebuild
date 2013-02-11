# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rack/rack-1.3.6-r1.ebuild,v 1.10 2013/01/16 00:40:54 zerochaos Exp $

EAPI="2"
USE_RUBY="ruby18 ree18 ruby19 jruby"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="ChangeLog KNOWN-ISSUES README.rdoc SPEC"

RUBY_FAKEGEM_BINWRAP=""

inherit ruby-fakegem eutils versionator

DESCRIPTION="A modular Ruby webserver interface"
HOMEPAGE="http://rubyforge.org/projects/rack"
SRC_URI="mirror://rubyforge/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="~alpha amd64 ~arm ~ia64 ppc ppc64 ~sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

ruby_add_rdepend "virtual/ruby-ssl"

# The gem has automagic dependencies over mongrel, ruby-openid,
# memcache-client, thin, mongrel and camping; not sure if we should
# make them dependencies at all. We do add the fcgi dependency because
# that spec isn't optional.
ruby_add_bdepend "test? ( dev-ruby/bacon dev-ruby/fcgi )"

# Block against versions in older slots that also try to install a binary.
RDEPEND="${RDEPEND} !<dev-ruby/rack-1.1.3-r1:0 !<dev-ruby/rack-1.2.5:1.2"

all_ruby_prepare() {
	epatch "${FILESDIR}"/${PN}-1.2.1-gentoo.patch

	# Avoid tests depending on now randomized hash ordering.
	sed -i -e '/foobarfoo/ s:^:#:' test/spec_response.rb || die
	sed -i -e '/build query strings correctly/,/end/ s:^:#:' test/spec_utils.rb || die
	sed -i -e '/build nested query strings correctly/,/end/ s:^:#:' test/spec_utils.rb || die
}

each_ruby_prepare() {
	case ${RUBY} in
		*jruby)
			# Avoid two failing tests due to bugs in jruby that should
			# be solved in 1.6.5 or 1.7.
			rm test/spec_deflater.rb || die
			;;
		*)
			;;
	esac
}

each_ruby_test() {
	# Since the Rakefile calls specrb directly rather than loading it, we
	# cannot use it to launch the tests or only the currently-selected
	# RUBY interpreter will be tested.
	${RUBY} -S bacon -Ilib -w -a \
		-q -t '^(?!Rack::Handler|Rack::Adapter|Rack::Session::Memcache|Rack::Server)' \
		|| die "test failed for ${RUBY}"
}
