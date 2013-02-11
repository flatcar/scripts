# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/highline/highline-1.6.15.ebuild,v 1.1 2012/12/22 08:11:15 graaff Exp $

EAPI=4

USE_RUBY="ruby18 ruby19 jruby ree18"

RUBY_FAKEGEM_EXTRADOC="CHANGELOG README.rdoc TODO"
RUBY_FAKEGEM_DOCDIR="doc/html"

inherit ruby-fakegem

DESCRIPTION="Highline is a high-level command-line IO library for ruby."
HOMEPAGE="http://highline.rubyforge.org/"

IUSE=""
LICENSE="|| ( GPL-2 Ruby )"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris ~x86-solaris"

all_ruby_prepare() {
	# fix up gemspec file not to call git
	sed -i -e '/git ls-files/d' highline.gemspec || die

	# Avoid tests that require a real console because we can't provide
	# that when running tests through portage. These should pass when
	# run in a console. We should probably narrow this down more to the
	# specific tests.
	sed -i -e '/\(tc_highline\|tc_menu\)/ s:^:#:' test/ts_all.rb || die
}

each_ruby_test() {
	case ${RUBY} in
		*jruby)
			ewarn "Skipping tests since they hang indefinitely."
			;;
		*)
			${RUBY} -S rake test || die
			;;
	esac
}
