# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/fssm/fssm-0.2.7-r1.ebuild,v 1.8 2013/01/15 06:46:46 zerochaos Exp $

EAPI=4

USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_TASK_TEST="spec"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.markdown"

inherit ruby-fakegem

DESCRIPTION="Monitor API"
HOMEPAGE="http://github.com/ttilley/fssm"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

# rb-inotify is a Linux-specific extension, so we will need to make this
# conditional when keywords are added that are not linux-specific.
ruby_add_rdepend "kernel_linux? ( >=dev-ruby/rb-inotify-0.8.6-r1 )"

ruby_add_bdepend "test? ( >=dev-ruby/rspec-2.4.0:2 )"

all_ruby_prepare() {
	# Remove bundler support
	sed -i -e '/[Bb]undler/d' Rakefile spec/spec_helper.rb || die
	rm Gemfile || die

	# Fix/ignore broken specs with patch from upstream
	epatch "${FILESDIR}/${P}-test.patch"
}

all_ruby_install() {
	all_fakegem_install

	dodoc example.rb
}
