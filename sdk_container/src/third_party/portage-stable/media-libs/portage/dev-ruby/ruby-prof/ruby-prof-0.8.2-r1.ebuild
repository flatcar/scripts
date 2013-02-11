# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-prof/ruby-prof-0.8.2-r1.ebuild,v 1.1 2010/08/08 18:03:58 graaff Exp $

EAPI=2

# jruby → not compatible, since it uses an extension
USE_RUBY="ruby18 ruby19"

RUBY_FAKEGEM_EXTRADOC="README CHANGES"
RUBY_FAKEGEM_DOCDIR="doc"

inherit multilib ruby-fakegem

DESCRIPTION="A module for profiling Ruby code"
HOMEPAGE="http://rubyforge.org/projects/ruby-prof/"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

ruby_add_bdepend "test? ( virtual/ruby-test-unit )"

all_ruby_prepare() {
	# The thread testing in 0.8.1 and earlier versions is broken, it
	# has to be tested for the next versions, since upstream is
	# looking for a solution. The problem is that it's _very_
	# timing-dependent.
	rm "${S}"/test/thread_test.rb \
		|| die "unable to remove broken test unit"
	sed -i -e '/thread_test/d' \
		test/test_suite.rb || die "unable to remove broken test reference"

	# We install the shared object in lib, not ext.
	sed -i -e 's#../ext/ruby_prof#../lib/ruby_prof#' lib/ruby-prof.rb
}

each_ruby_prepare() {
	case ${RUBY} in
		*ruby19)
			# On ruby 1.9 this test fails badly, so we disable it
			# until upstream can fix the related bug:
			# http://redmine.ruby-lang.org/issues/show/2012
			sed -i -e '/^  def test_flat_string_with_numbers/,/^  end/ s:^:#:' \
				test/printers_test.rb || die "Unable to disable test_flat_string_with_numbers"
			;;
	esac
}

each_ruby_configure() {
	${RUBY} -Cext/ruby_prof extconf.rb || die "extconf.rb failed"
}

each_ruby_compile() {
	# gem ships with prebuild files
	emake -Cext/ruby_prof clean || die "clean failed"
	emake -Cext/ruby_prof || die "build failed"

	mkdir lib/ruby_prof || die "unable to create directory for shared object"
	cp ext/ruby_prof/*$(get_modname) lib/ruby_prof || die "copy of extension failed"
}

all_ruby_install() {
	all_fakegem_install

	for dir in examples rails rails/example rails/environment; do
		docinto "$dir"
		dodoc "$dir"/* || die "dodoc $dir failed"
	done
}
