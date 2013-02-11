# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/coderay/coderay-1.0.0.ebuild,v 1.3 2012/10/28 17:38:33 armin76 Exp $

EAPI=4

USE_RUBY="ruby18 ree18 ruby19 jruby"

# The test target also contains test:exe but that requires
# shoulda-context which we do not have packaged yet.
RUBY_FAKEGEM_TASK_TEST="test:functional test:units"

RUBY_FAKEGEM_TASK_DOC="doc"
RUBY_FAKEGEM_DOCDIR="doc"

RUBY_FAKEGEM_EXTRADOC="Changes-1.0.textile Changes.textile IDEA README.textile TODO"

inherit ruby-fakegem

DESCRIPTION="A Ruby library for syntax highlighting."
HOMEPAGE="http://coderay.rubychan.de/"
SRC_URI="https://github.com/rubychan/coderay/tarball/v${PV} -> ${P}.tgz"

RUBY_S="rubychan-coderay-*"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x86-solaris"
IUSE=""

# Redcloth is optional but automagically tested, so we add this
# dependency to ensure that we get at least a version that works: bug
# 330621. We use this convoluted way because redcloth isn't available
# yet for jruby.
USE_RUBY="${USE_RUBY/jruby/}" ruby_add_bdepend "test? ( >=dev-ruby/redcloth-4.2.2 )"

all_ruby_prepare() {
	# Don't run two tests that are known to break on jruby 1.5. We
	# should depend on jruby 1.6 to fix this, but only the tests are
	# broken. https://github.com/rubychan/coderay/issues/4
	sed -i -e '22,35d' test/unit/file_type.rb || die
	sed -i -e '48,61d' test/unit/plugin.rb || die
}
