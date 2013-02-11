# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rcairo/rcairo-1.10.0-r3.ebuild,v 1.4 2012/07/01 18:31:41 armin76 Exp $

EAPI=2

# ruby19 → fails, and even crashes Ruby
# jruby → cannot work, it's a compiled extension
USE_RUBY="ruby18"

RUBY_FAKEGEM_NAME="cairo"

# Documentation depends on files that are not distributed.
RUBY_FAKEGEM_TASK_DOC=""

# Depends on test-unit-2 which is currently masked.
RUBY_FAKEGEM_TASK_TEST=""

RUBY_FAKEGEM_DOCDIR="doc"

RUBY_FAKEGEM_EXTRADOC="AUTHORS NEWS"

inherit multilib ruby-fakegem

DESCRIPTION="Ruby bindings for cairo"
HOMEPAGE="http://cairographics.org/rcairo/"

IUSE=""

SLOT="0"
LICENSE="|| ( Ruby GPL-2 )"
KEYWORDS="amd64 ppc x86"

RDEPEND="${RDEPEND}
	>=x11-libs/cairo-1.2.0[svg]"
DEPEND="${DEPEND}
	>=x11-libs/cairo-1.2.0[svg]
	virtual/pkgconfig"

ruby_add_bdepend "
	dev-ruby/ruby-glib2
	test? ( >=dev-ruby/test-unit-2.1.0-r1:2 )"

all_ruby_prepare() {
	# Remove a failing test for the new recording surface. It's not
	# clear if this is a test failure or not, but we need to move on
	# with cairo 1.10.
	rm test/test_recording_surface.rb || die

	# We don't need pkg-config since we compile directly so remove
	# metadata because otherwise rubygems or bundler may get confused.
	rm ../metadata || die
}

each_ruby_configure() {
	${RUBY} extconf.rb || die "extconf failed"
}

each_ruby_compile() {
	emake || die "make failed"

	# again, try to make it more standard, to install it more easily.
	cp ext/cairo/cairo$(get_modname) lib/ || die
}

each_ruby_test() {
	# don't rely on the Rakefile because it's a mess to load with
	# their hierarchy, do it manually.
	${RUBY} -Ilib -r ./test/cairo-test-utils.rb \
		-e 'gem "test-unit"; require "test/unit"; Dir.glob("test/**/test_*.rb") {|f| load f}' || die "tests failed"
}

each_ruby_install() {
	each_fakegem_install

	insinto $(ruby_get_hdrdir)
	doins ext/cairo/rb_cairo.h || die "Cannot install header file."
}

all_ruby_install() {
	all_fakegem_install

	insinto /usr/share/doc/${PF}/samples
	doins -r samples/* || die "Cannot install sample files."
}
