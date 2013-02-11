# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/mkrf/mkrf-0.2.3-r1.ebuild,v 1.12 2012/07/01 18:31:42 armin76 Exp $

EAPI="2"
USE_RUBY="ruby18"

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
KEYWORDS="amd64 ppc x86"

IUSE=""

ruby_add_bdepend "test? ( virtual/ruby-test-unit )"

DEPEND="${DEPEND} test? ( virtual/libiconv dev-libs/libxml2 )"
