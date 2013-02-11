# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/cerberus/cerberus-0.8.0.ebuild,v 1.2 2012/12/17 15:43:57 ago Exp $

EAPI="3"
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="Authors.txt Changelog.txt Readme.markdown"

inherit ruby-fakegem

DESCRIPTION="Continuous Integration tool for ruby projects"
HOMEPAGE="http://rubyforge.org/projects/cerberus"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
IUSE=""

# The json dependency is indirect via the vendored twitter code.
ruby_add_rdepend "=dev-ruby/actionmailer-2*
	=dev-ruby/activesupport-2*
	>=dev-ruby/rake-0.7.3
	dev-ruby/json"

ruby_add_bdepend "test? ( virtual/ruby-test-unit dev-ruby/rubyzip )"

DEPEND="${DEPEND} test? ( dev-vcs/subversion dev-vcs/git )"
RDEPEND="${RDEPEND}"

# TODO: cerberus bundles several packages: addressable, shout-bot,
# tinder, twitter, and xmpp4r. Some of these are very
# version-dependant, so it is not easy to determine whether they can
# be unbundeled.

all_ruby_prepare() {
	# Some of these tests fail and upstream indicates that the test
	# suite currently isn't well-maintained:
	# https://github.com/cpjolicoeur/cerberus/issues/15
	rm test/functional_test.rb || die
}
