# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rdtool/rdtool-0.6.22-r2.ebuild,v 1.1 2012/07/29 07:15:40 graaff Exp $

EAPI=4
USE_RUBY="ruby18 ruby19 ree18 jruby"

inherit elisp-common ruby-ng

DESCRIPTION="A multipurpose documentation format for Ruby"
HOMEPAGE="http://raa.ruby-lang.org/project/rdtool"
SRC_URI="http://www.moonwolf.com/ruby/archive/${P}.tar.gz"
LICENSE="Ruby GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE="emacs"

RDEPEND="${RDEPEND} emacs? ( virtual/emacs )"

SITEFILE=50${PN}-gentoo.el

each_ruby_test() {
	${RUBY} -Ilib:. test.rb || die
}

each_ruby_install() {
	RUBY_ECONF="${RUBY_ECONF} ${EXTRA_ECONF}"

	${RUBY} setup.rb config --prefix=/usr "$@" \
		${RUBY_ECONF} || die "setup.rb config failed"
	${RUBY} setup.rb install --prefix="${D}" "$@" \
		${RUBY_ECONF} || die "setup.rb install failed"
}

all_ruby_install() {
	if use emacs ; then
		elisp-install ${PN} utils/rd-mode.el
		elisp-site-file-install "${FILESDIR}/${SITEFILE}"
	fi

	dodoc HISTORY README.*
}

pkg_postinst() {
	use emacs && elisp-site-regen
}

pkg_postrm() {
	use emacs && elisp-site-regen
}
