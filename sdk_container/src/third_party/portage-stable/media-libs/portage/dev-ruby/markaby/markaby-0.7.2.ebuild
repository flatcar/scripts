# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/markaby/markaby-0.7.2.ebuild,v 1.4 2012/05/01 18:24:28 armin76 Exp $

EAPI=2
USE_RUBY="ruby18 ree18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="CHANGELOG.rdoc README.rdoc"

RUBY_FAKEGEM_TASK_TEST="test spec"

RUBY_FAKEGEM_EXTRAINSTALL="init.rb VERSION"

inherit ruby-fakegem

DESCRIPTION="A templating language for Ruby to write HTML templates in pre Ruby"
HOMEPAGE="http://markaby.github.com/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~ppc64 ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE=""

ruby_add_bdepend "test? ( virtual/ruby-test-unit dev-ruby/rspec:2 dev-ruby/tilt )"
ruby_add_rdepend ">=dev-ruby/builder-2.0.0"

all_ruby_prepare() {
	# Add missing require to fix spec. The associated failure depended
	# on load order of the specs, bug 343693.
	sed -i -e "10irequire 'markaby/tilt'" spec/spec_helper.rb || die
}
