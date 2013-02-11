# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/minitest/minitest-3.5.0.ebuild,v 1.9 2013/01/01 19:33:14 armin76 Exp $

EAPI=4
# jruby → tests fail, reported upstream
# http://rubyforge.org/tracker/index.php?func=detail&aid=27657&group_id=1040&atid=4097
USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_TASK_DOC="docs"

RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="History.txt Manifest.txt README.txt"

inherit ruby-fakegem

DESCRIPTION="minitest/unit is a small and fast replacement for ruby's huge and slow test/unit."
HOMEPAGE="https://github.com/seattlerb/minitest"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

ruby_add_bdepend "
	doc? ( dev-ruby/hoe dev-ruby/rdoc )
	test? (
		dev-ruby/rdoc
		dev-ruby/hoe
	)"

each_ruby_prepare() {
	case ${RUBY} in
		*jruby)
			# Remove failing tests. Upstream claims that these are all
			# bugs in jruby. By removing the failing tests we can at
			# least run the remainder. See bug 321055 for details.
			rm -f test/minitest/test_minitest_unit.rb || die
			# Also add minitest_mock since there are jruby-specific failures.
			rm -f test/minitest/test_minitest_mock.rb || die

			# Our jruby throws a slightly different error
			sed -i -e 's/not :xxx/not \\"xxx\\"/' test/minitest/test_minitest_spec.rb || die
				;;
		*)
				;;
	esac
}
