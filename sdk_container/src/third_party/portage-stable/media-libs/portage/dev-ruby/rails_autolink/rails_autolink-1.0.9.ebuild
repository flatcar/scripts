# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rails_autolink/rails_autolink-1.0.9.ebuild,v 1.1 2013/01/25 20:50:24 flameeyes Exp $

EAPI=5
USE_RUBY="ruby19"

RUBY_FAKEGEM_RECIPE_TEST="none"
RUBY_FAKEGEM_RECIPE_DOC="rdoc"

inherit ruby-fakegem

DESCRIPTION="This is an extraction of the auto_link method from rails."
HOMEPAGE="http://github.com/tenderlove/rails_autolink"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc test"

RUBY_PATCHES=( ${P}-fixes.patch )

ruby_add_bdepend "test? ( dev-ruby/minitest )"

ruby_add_rdepend ">=dev-ruby/rails-3.1"

each_ruby_test() {
	${RUBY} -Ilib test/test_*.rb || die "tests failed"
}
