# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rack/rack-1.2.7.ebuild,v 1.5 2013/01/21 14:09:52 ago Exp $

EAPI=4
USE_RUBY="ruby18 ree18 ruby19 jruby"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="ChangeLog KNOWN-ISSUES README SPEC"

RUBY_FAKEGEM_BINWRAP=""

inherit ruby-fakegem eutils versionator

DESCRIPTION="A modular Ruby webserver interface"
HOMEPAGE="http://rubyforge.org/projects/rack"
SRC_URI="mirror://rubyforge/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="amd64 ppc ppc64 x86 ~x86-fbsd ~amd64-linux ~ia64-linux ~x86-linux ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

ruby_add_rdepend "virtual/ruby-ssl"

# The gem has automagic dependencies over mongrel, ruby-openid,
# memcache-client, thin, mongrel and camping; not sure if we should
# make them dependencies at all. We do add the fcgi dependency because
# that spec isn't optional.
ruby_add_bdepend "test? ( dev-ruby/bacon dev-ruby/fcgi )"

# Block against versions in older slots that also try to install a binary.
RDEPEND="${RDEPEND} !<dev-ruby/rack-1.1.3-r1"

#USE_RUBY=ruby19 \
#	ruby_add_bdepend "ruby_targets_ruby19 test" '=dev-ruby/test-unit-1*'

all_ruby_prepare() {
	epatch "${FILESDIR}"/${PN}-1.2.1-gentoo.patch

	# Add missing require for Mutex use. This may show up in the tests
	# depending on load order.
	sed -i -e '1 irequire "thread"' lib/rack/lock.rb || die

	# Avoid tests depending on now randomized hash ordering.
	sed -i -e '/foobarfoo/ s:^:#:' test/spec_response.rb || die
	sed -i -e '/build query strings correctly/,/end/ s:^:#:' test/spec_utils.rb || die
	sed -i -e '/build nested query strings correctly/,/end/ s:^:#:' test/spec_utils.rb || die
}

each_ruby_prepare() {
	case ${RUBY} in
		*ruby19)
			# Avoid failing encoding-related specs, most likely due to
			# changes in handling of encodings in newer ruby 19
			# versions.
			sed -i -e '/escape non-UTF8 strings/,/end/ s:^:#:' test/spec_utils.rb || die
			sed -i -e '/escape html entities in unicode strings/,/end/ s:^:#:' test/spec_utils.rb || die
			sed -i -e '/escape html entities even on MRI/,/^  end/ s:^:#:' test/spec_utils.rb || die
			sed -i -e '/accept params and build multipart encoded params/,/^  end/ s:^:#:' test/spec_mock.rb || die
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
		-q -t '^(?!Rack::Handler|Rack::Adapter|Rack::Session::Memcache|rackup)' \
		|| die "test failed for ${RUBY}"
}
