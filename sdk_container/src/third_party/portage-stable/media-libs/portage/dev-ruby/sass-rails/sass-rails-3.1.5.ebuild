# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/sass-rails/sass-rails-3.1.5.ebuild,v 1.6 2012/09/17 19:24:21 grobian Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="CHANGELOG.md README.markdown"

inherit ruby-fakegem

DESCRIPTION="Official Ruby-on-Rails Integration with Sass"
HOMEPAGE="https://github.com/rails/sass-rails"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~x64-macos ~x86-solaris"

IUSE=""

ruby_add_bdepend "test? ( dev-ruby/sfl dev-ruby/bundler )"

ruby_add_rdepend ">=dev-ruby/sass-3.1.10
	dev-ruby/railties:3.1
	dev-ruby/actionpack:3.1
	>=dev-ruby/tilt-1.3.2"

each_ruby_test() {
	${RUBY} -S bundle exec rake test || die
}
