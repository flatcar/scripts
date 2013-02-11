# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/mkrf/mkrf-0.2.3-r2.ebuild,v 1.12 2013/01/08 08:39:53 nativemad Exp $

EAPI="2"
USE_RUBY="ruby18 ruby19"

RUBY_FAKEGEM_EXTRADOC="CHANGELOG README"
RUBY_FAKEGEM_DOCDIR="html"

# The unit tests (test:units) fail so skip them for now, since we have
# had this version in our tree for a long time. No bug tracker to
# report this problem. :-(
RUBY_FAKEGEM_TASK_TEST="test:integration"

inherit ruby-fakegem

DESCRIPTION="mkrf is a library for generating Rakefiles, primarily intended for building C extentions for Ruby."
HOMEPAGE="http://mkrf.rubyforge.org/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 hppa ppc ppc64 x86"

IUSE=""

DEPEND="${DEPEND} test? ( virtual/libiconv dev-libs/libxml2 )"

each_ruby_test() {
	RUBYLIB=. ${RUBY} -S rake test:integration || die
}
