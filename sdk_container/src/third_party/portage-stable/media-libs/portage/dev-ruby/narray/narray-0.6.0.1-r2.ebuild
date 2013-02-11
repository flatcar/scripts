# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/narray/narray-0.6.0.1-r2.ebuild,v 1.5 2012/11/07 05:12:28 jer Exp $

EAPI=4

# jruby → native extension
USE_RUBY="ruby18 ree18 ruby19"

RUBY_FAKEGEM_TASK_TEST=""
RUBY_FAKEGEM_TASK_DOC=""

RUBY_FAKEGEM_EXTRADOC="ChangeLog README.en README.ja SPEC.en SPEC.ja"

RUBY_FAKEGEM_VERSION="${PV/_p/.}"

inherit multilib ruby-fakegem

DESCRIPTION="Numerical N-dimensional Array class"
HOMEPAGE="http://www.ir.isas.ac.jp/~masa/ruby/index-e.html"
SRC_URI="mirror://rubyforge/${PN}/${P/_/}.tar.gz"

LICENSE="Ruby"
SLOT="0"
KEYWORDS="amd64 hppa ~mips ppc ~ppc64 x86"

IUSE=""

all_ruby_prepare() {
	# the tests aren't really written to be a testsuite, so the
	# failure cases will literally fail; ignore all of those ad
	# instead expect that the rest won't fail.
	sed -i -e '/[fF]ollowing will fail/,$ s:^:#:' \
		test/*.rb || die "sed failed"
}

each_ruby_configure() {
	${RUBY} extconf.rb || die "extconf.rb failed"
}

each_ruby_compile() {
	emake CFLAGS="${CFLAGS} -fPIC" archflag="${LDFLAGS}" || die "emake failed"
	cp -l ${PN}$(get_modname) ${PN}.h ${PN}_config.h lib/ || die "copy of ${PN}$(get_modname) failed"
}

each_ruby_test() {
	for unit in test/*; do
		# Skip over the FFTW test because it needs a package we don't
		# have in tree.
		[[ ${unit} == test/testfftw.rb ]] && continue

		${RUBY} -Ilib ${unit} || die "test ${unit} failed"
	done
}
