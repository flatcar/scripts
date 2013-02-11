# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/bcat/bcat-0.6.2.ebuild,v 1.9 2013/01/15 05:19:20 zerochaos Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_DOC="man"
RUBY_FAKEGEM_EXTRADOC="README"

inherit ruby-fakegem

DESCRIPTION="A pipe to browser utility for use at the shell and within editors like Vim or Emacs."
HOMEPAGE="http://github.com/rtomayko/bcat"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE=""

# Collides on /usr/bin/bcat, bug 418301
RDEPEND="${RDEPEND} !!app-accessibility/speech-tools"

ruby_add_bdepend "doc? ( app-text/ronn )"
ruby_add_bdepend "test? ( virtual/ruby-test-unit )"

ruby_add_rdepend "dev-ruby/rack"

each_ruby_prepare() {
	sed -i -e "s/a2h/#{ENV['RUBY']} -S a2h/" test/test_bcat_a2h.rb || die
}

each_ruby_test() {
	# The Rakefile uses weird trickery with load path that causes gems
	# not to be found. Run tests directly instead and do the trickery
	# here to support popen calls for the bins in this package.
	RUBY=${RUBY} RUBYLIB=lib:${RUBYLIB} PATH=bin:${PATH} ${RUBY} -S testrb test/test_*.rb || die
}

all_ruby_install() {
	all_fakegem_install

	doman man/*.1
}
