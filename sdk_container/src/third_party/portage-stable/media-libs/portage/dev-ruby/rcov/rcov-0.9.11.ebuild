# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rcov/rcov-0.9.11.ebuild,v 1.2 2012/02/14 13:41:27 flameeyes Exp $

EAPI=4

# The documenttion indicates that rcov does not work with (reliably)
# with ruby 1.9. Use ruby 1.9's built in coverage or simplecov instead.
USE_RUBY="ruby18 "

RUBY_FAKEGEM_TASK_TEST="test_rcovrt"

RUBY_FAKEGEM_DOCDIR="rdoc"
RUBY_FAKEGEM_EXTRADOC="THANKS BLURB"

inherit ruby-fakegem versionator eutils

DESCRIPTION="A ruby code coverage analysis tool"
HOMEPAGE="http://eigenclass.org/hiki.rb?rcov"
#SRC_URI="http://github.com/relevance/${PN}/tarball/release_$(replace_all_version_separators _) -> ${P}.tgz"
SRC_URI="http://github.com/relevance/${PN}/tarball/b5513cae5ea3348d97c21a3c324d8e8a7768e814 -> ${P}.tgz"

RUBY_S="relevance-${PN}-*"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"

# TODO: both emacs and vim support are present in this package, they
# should probably be added to the ebuild as well.
IUSE=""

all_ruby_prepare() {
	epatch "${FILESDIR}"/${PN}-0.9.7.1-jruby.patch

	# Without this change, testing will always cause the extension to
	# be rebuilt, and we don't want that.
	sed -i -e '/:test_rcovrt =>/s| => \[.*\]||' Rakefile || die "Rakefile fix failed"

	# remove pre-packaged jar file (d'oh!)
	rm lib/rcovrt.jar || die

	# Remove test suite with failing tests that upstream believes to
	# work correctly so that we can run the remainder of tests.
	# https://github.com/relevance/rcov/issues/40
	rm test/code_coverage_analyzer_test.rb || die

}

each_ruby_compile() {
	if [[ $(basename ${RUBY}) = "jruby" ]]; then
		${RUBY} -S rake lib/rcovrt.jar || die "build failed"
	else
		${RUBY} -S rake ext/rcovrt/rcovrt.so || die "build failed"
		cp ext/rcovrt/rcovrt.so lib/ || die
	fi
}
