# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-prof/ruby-prof-0.10.7.ebuild,v 1.1 2011/05/10 06:09:45 graaff Exp $

EAPI=4

# jruby → not compatible, since it uses an extension, but there is a bug
# open for it: https://github.com/rdp/ruby-prof/issues/36

USE_RUBY="ruby18 ruby19 ree18"

RUBY_FAKEGEM_EXTRADOC="README.rdoc CHANGES"
RUBY_FAKEGEM_DOCDIR="doc"

inherit multilib ruby-fakegem

DESCRIPTION="A module for profiling Ruby code"
HOMEPAGE="https://github.com/rdp/ruby-prof"
SRC_URI="https://github.com/rdp/${PN}/tarball/${PV} -> ${P}.tgz"
RUBY_S="rdp-${PN}-*"

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
#	rm "${S}"/test/thread_test.rb \
#		|| die "unable to remove broken test unit"
#	sed -i -e '/thread_test/d' \
#		test/test_suite.rb || die "unable to remove broken test reference"

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
	emake -Cext/ruby_prof || die "build failed"

	mkdir lib/ruby_prof || die "unable to create directory for shared object"
	cp ext/ruby_prof/*$(get_modname) lib/ruby_prof || die "copy of extension failed"
}

all_ruby_install() {
	all_fakegem_install

	for dir in examples rails rails/example rails/environment; do
		docinto "$dir"
		dodoc -r "$dir"/* || die "dodoc $dir failed"
	done
}
