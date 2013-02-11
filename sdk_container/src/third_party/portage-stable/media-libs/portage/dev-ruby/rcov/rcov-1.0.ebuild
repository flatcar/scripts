# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rcov/rcov-1.0.ebuild,v 1.1 2012/02/14 13:41:27 flameeyes Exp $

EAPI=4

# The documenttion indicates that rcov does not work with (reliably)
# with ruby 1.9. Use ruby 1.9's built in coverage or simplecov instead.
USE_RUBY="ruby18"

RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_DOCDIR="rdoc"
RUBY_FAKEGEM_EXTRADOC="THANKS BLURB README.markdown"

inherit ruby-fakegem versionator eutils

DESCRIPTION="A ruby code coverage analysis tool"
HOMEPAGE="http://eigenclass.org/hiki.rb?rcov"
#SRC_URI="http://github.com/relevance/${PN}/tarball/release_$(replace_all_version_separators _) -> ${P}.tgz"
SRC_URI="http://github.com/relevance/${PN}/tarball/e7c1821b50bef0f933ef857278bf82e9c24638e4 -> ${P}.tgz"

RUBY_S="relevance-${PN}-*"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"

# TODO: both emacs and vim support are present in this package, they
# should probably be added to the ebuild as well.
IUSE=""

ruby_add_bdepend "doc? ( dev-ruby/rdoc )"

# upstream's Rakefile is braindead and just asking for rake -D causes
# the extension to be rebuilt, so do everything by hand.

each_ruby_configure() {
	${RUBY} -C ext/rcovrt extconf.rb || die "extconf.rb failed"
}

each_ruby_compile() {
	emake -C ext/rcovrt CFLAGS="${CFLAGS} -fPIC" archflag="${LDFLAGS}"
	cp ext/rcovrt/*.so lib/ || die
}

all_ruby_compile() {
	if use doc; then
		rdoc --op rdoc || die
	fi
}

each_ruby_test() {
	${RUBY} -Ilib -S testrb test/*_test.rb
}
