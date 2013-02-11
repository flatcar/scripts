# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/dnsruby/dnsruby-1.53.ebuild,v 1.2 2012/08/05 09:58:46 graaff Exp $

EAPI=4

# jruby → fails tests.
USE_RUBY="ruby18 ruby19 ree18"
RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_DOCDIR="html"
RUBY_FAKEGEM_EXTRADOC="DNSSEC EXAMPLES README"
inherit ruby-fakegem

DESCRIPTION="A pure Ruby DNS client library"
HOMEPAGE="http://rubyforge.org/projects/dnsruby/"

KEYWORDS="~amd64 ~x86"
LICENSE="Apache-2.0"
SLOT="0"
IUSE=""

all_ruby_prepare() {
	# Avoid test failing when an IPv6 resolver is present. Already fixed
	# upstream but not in an easy-to-backport way.
	sed -i -e '/test_single_resolver/,/^  end/ s:^:#:' test/tc_res_config.rb || die
}

each_ruby_test() {
	# only run offline tests
	#${RUBY} -I .:lib test/ts_dnsruby.rb || die "test failed"
	${RUBY} -I .:lib test/ts_offline.rb || die "test failed"
}
