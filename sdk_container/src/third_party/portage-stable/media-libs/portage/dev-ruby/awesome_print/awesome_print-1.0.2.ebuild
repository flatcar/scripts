# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/awesome_print/awesome_print-1.0.2.ebuild,v 1.3 2012/10/28 17:16:52 armin76 Exp $

EAPI=2
USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_RECIPE_TEST="rspec"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_EXTRADOC="CHANGELOG README.md"

inherit ruby-fakegem

DESCRIPTION="Ruby library that pretty prints Ruby objects in full color with proper indentation."
HOMEPAGE="http://github.com/michaeldv/awesome_print"
LICENSE="MIT"

KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
SLOT="0"
IUSE=""

all_ruby_prepare() {
	# Avoid intermittent hash-ordering test failure:
	# https://github.com/michaeldv/awesome_print/issues/74
	sed -i -e '/handle array grep when pattern contains/,/end/ s:^:#:' spec/formats_spec.rb || die
	sed -i -e '/should pass the matching string within the block/,/^  end/ s:^:#:' spec/methods_spec.rb || die
}
