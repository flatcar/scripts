# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/sass/sass-3.1.21.ebuild,v 1.4 2013/01/15 06:47:25 zerochaos Exp $

EAPI=2

USE_RUBY="ruby18 ruby19 ree18 jruby"

RUBY_FAKEGEM_TASK_DOC=""
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC="README.md"

RUBY_FAKEGEM_EXTRAINSTALL="rails init.rb VERSION VERSION_NAME"

inherit ruby-fakegem

DESCRIPTION="An extension of CSS3, adding nested rules, variables, mixins, selector inheritance, and more."
HOMEPAGE="http://sass-lang.com/"
LICENSE="MIT"

KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x64-macos"
SLOT="0"
IUSE=""

ruby_add_bdepend "doc? ( >=dev-ruby/yard-0.5.3 >=dev-ruby/maruku-0.5.9 )"

ruby_add_rdepend ">=dev-ruby/listen-0.4.2 !!<dev-ruby/haml-3.1"

# tests could use `less` if we had it

all_ruby_prepare() {
	rm -rf vendor/listen
}

each_ruby_prepare() {
	case ${RUBY} in
		*jruby)
			# tests fail with JRuby, and that's a given for now; it's
			# not a bug in the code as much as it is relying on a detail
			# of the implementation of CRuby. We remove failing files
			# for now, this could probably be narrowed down more so that
			# we could run more tests.
			rm test/sass/script_test.rb test/sass/util_test.rb test/sass/engine_test.rb test/sass/scss/scss_test.rb || die
			;;
		*)
			;;
	esac
}
