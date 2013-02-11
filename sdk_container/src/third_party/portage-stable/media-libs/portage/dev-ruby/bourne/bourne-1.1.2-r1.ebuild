# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/bourne/bourne-1.1.2-r1.ebuild,v 1.1 2012/08/02 05:36:09 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="README.md"

RUBY_FAKEGEM_TASK_TEST="test:units test:acceptance"

RUBY_FAKEGEM_GEMSPEC="${PN}.gemspec"

inherit ruby-fakegem

DESCRIPTION="Extends mocha to allow detailed tracking and querying of stub and mock invocations."
HOMEPAGE="http://github.com/thoughtbot/bourne"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

ruby_add_rdepend ">=dev-ruby/mocha-0.10.5"

all_ruby_prepare() {
	sed -i \
		-e '/git ls-files/d' \
		-e '/dependency.*mocha/s:= 0.10.5:>= 0.10.5:' \
		"${RUBY_FAKEGEM_GEMSPEC}" || die

	sed -i -e '/bundler/d' Rakefile || die
}
