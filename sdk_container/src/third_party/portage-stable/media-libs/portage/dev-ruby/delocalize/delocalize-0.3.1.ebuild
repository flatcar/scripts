# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/delocalize/delocalize-0.3.1.ebuild,v 1.2 2012/08/16 03:52:53 flameeyes Exp $

EAPI=4

# ruby19 → tests failure related to DST
# jruby → timecop fails badly, and the
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_EXTRADOC="README.markdown"

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

GITHUB_USER="clemens"
GITHUB_PROJECT="${PN}"
RUBY_S="${GITHUB_USER}-${GITHUB_PROJECT}-*"

inherit ruby-fakegem

DESCRIPTION="A tool for parsing localized dates/times and numbers"
HOMEPAGE="http://github.com/clemens/delocalize"

SRC_URI="https://github.com/${GITHUB_USER}/${GITHUB_PROJECT}/tarball/v${PV} -> ${GITHUB_PROJECT}-${PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

ruby_add_rdepend ">=dev-ruby/rails-3"

ruby_add_bdepend "
	test? (
		>=dev-ruby/sqlite3-1.3.4-r1
		dev-ruby/timecop
	)"
