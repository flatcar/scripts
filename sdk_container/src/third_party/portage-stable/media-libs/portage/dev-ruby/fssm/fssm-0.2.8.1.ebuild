# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/fssm/fssm-0.2.8.1.ebuild,v 1.6 2013/01/15 06:46:46 zerochaos Exp $

EAPI=4

USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_RECIPE_TEST="rspec"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.markdown"

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

inherit ruby-fakegem

DESCRIPTION="File System State Monitor API"
HOMEPAGE="http://github.com/ttilley/fssm"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

# rb-inotify is a Linux-specific extension, so we will need to make this
# conditional when keywords are added that are not linux-specific.
ruby_add_rdepend "kernel_linux? ( >=dev-ruby/rb-inotify-0.8.6-r1 )"

all_ruby_prepare() {
	# Remove bundler support
	sed -i -e '/[Bb]undler/d' Rakefile spec/spec_helper.rb || die
	rm Gemfile || die

	# Fix/ignore broken specs with patch from upstream
	epatch "${FILESDIR}/${PN}-0.2.7-test.patch"

	# if we're going to require rb-inotify, let's make sure it gets used
	# as well; if we don't declare it in the dependencies this will not
	# be loaded by bundler-based projects to begin with.
	if use kernel_linux; then
		sed -i -e '/^end/i s.add_dependency "rb-inotify"' ${RUBY_FAKEGEM_GEMSPEC} || die
	fi

	# Avoid a dependency on git.
	sed -i -e '/git ls-files/d' ${PN}.gemspec || die
}

all_ruby_install() {
	all_fakegem_install

	dodoc example.rb
}
