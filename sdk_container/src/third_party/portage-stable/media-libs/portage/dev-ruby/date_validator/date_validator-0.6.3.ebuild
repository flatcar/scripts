# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/date_validator/date_validator-0.6.3.ebuild,v 1.1 2012/01/22 11:26:25 flameeyes Exp $

EAPI=4
USE_RUBY="ruby18 ree18 ruby19"

RUBY_FAKEGEM_TASK_TEST="test"

RUBY_FAKEGEM_TASK_DOC="docs"
RUBY_FAKEGEM_EXTRADOC="Readme.md"

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

# if ever needed
#GITHUB_USER="codegram"
#GITHUB_PROJECT="${PN}"
#RUBY_S="${GITHUB_USER}-${GITHUB_PROJECT}-*"

inherit ruby-fakegem

DESCRIPTION="Simple, ORM agnostic, Ruby 1.9 compatible date validator for Rails 3"
HOMEPAGE="http://github.com/codegram/date_validator"

LICENSE="MIT"
SLOT="3"
KEYWORDS="~amd64"
IUSE=""

ruby_add_rdepend ">=dev-ruby/activemodel-3.0
"

ruby_add_bdepend "
	test? (
		dev-ruby/minitest
		>=dev-ruby/tzinfo-0.3
		>=dev-ruby/activesupport-3.0
	)
	doc? ( dev-ruby/yard )"

all_ruby_prepare() {
	sed -i \
		-e '/git ls-files/d' \
		${RUBY_FAKEGEM_GEMSPEC} || die
}
