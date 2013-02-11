# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/bundler/bundler-1.0.22.ebuild,v 1.6 2013/01/16 00:28:32 zerochaos Exp $

EAPI=2

# jruby → needs to be tested because jruby-1.5.1 fails in multiple
# ways unrelated to this package.
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_TEST="spec"

# No documentation task
RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.md CHANGELOG.md ISSUES.md UPGRADING.md"

inherit ruby-fakegem

DESCRIPTION="An easy way to vendor gem dependencies"
HOMEPAGE="http://github.com/carlhuda/bundler"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~arm ~ppc ~ppc64 x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

ruby_add_rdepend virtual/rubygems

ruby_add_bdepend "test? ( app-text/ronn dev-ruby/rspec:2 )"

RDEPEND="${RDEPEND}
	dev-vcs/git"
DEPEND="${DEPEND}
	test? ( dev-vcs/git )"

all_ruby_prepare() {
	# Reported upstream: http://github.com/carlhuda/bundler/issues/issue/738
	sed -i -e '726s/should/should_not/' spec/runtime/setup_spec.rb || die

	# Fails randomly and no clear cause can be found. Might be related
	# to bug 346357. This was broken in previous releases without a
	# failing spec, so patch out this spec for now since it is not a
	# regression.
	sed -i -e '49,54d' spec/install/deploy_spec.rb || die
}

each_ruby_prepare() {
	case ${RUBY} in
		*ruby19)
			# Account for different wording in ruby 1.9.3.
			sed -i -e 's/no such file to load/cannot load such file/' spec/runtime/require_spec.rb spec/install/gems/groups_spec.rb || die
			;;
		*)
			;;
	esac
}
