# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/locale/locale-2.0.5-r3.ebuild,v 1.15 2013/01/15 05:30:13 zerochaos Exp $

EAPI=2

USE_RUBY="ruby18 ruby19 jruby ree18"

RUBY_FAKEGEM_TASK_DOC="rerdoc"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="ChangeLog README.rdoc"

RUBY_FAKEGEM_TASK_TEST="test"

inherit ruby-fakegem

DESCRIPTION="A pure ruby library which provides basic APIs for localization."
HOMEPAGE="http://locale.rubyforge.org/"
LICENSE="|| ( Ruby GPL-2 )"

KEYWORDS="alpha amd64 ~arm hppa ia64 ppc ppc64 sparc x86 ~x86-macos"
SLOT="0"
IUSE=""

ruby_add_bdepend "test? ( || ( virtual/ruby-test-unit dev-ruby/test-unit:2 ) )"

RUBY_PATCHES=( "${FILESDIR}/${PN}-language-fixes.patch" )

all_ruby_prepare() {
	# Avoid automagic dependency on allison, bug 334937
	sed -i -e '/allison/ s:^:#:' Rakefile || die
}

each_ruby_prepare() {
	case ${RUBY} in
		*jruby)
			# Remove broken test. It's not clear if the test or code is
			# broken... https://github.com/mutoh/locale/issues/2
			rm test/test_detect_general.rb || die
			;;
		*)
			;;
	esac
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}
	doins -r samples || die
}
