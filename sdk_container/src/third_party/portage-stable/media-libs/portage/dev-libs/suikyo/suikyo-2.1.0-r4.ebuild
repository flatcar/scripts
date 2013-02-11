# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/suikyo/suikyo-2.1.0-r4.ebuild,v 1.1 2012/02/05 02:38:28 matsuu Exp $

EAPI="2"
# ruby19: failed
USE_RUBY="ruby18 ree18 jruby rbx"
inherit elisp-common ruby-ng

DESCRIPTION="Romaji Hiragana conversion library"
HOMEPAGE="http://taiyaki.org/suikyo/"
SRC_URI="http://prime.sourceforge.jp/src/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ppc ~ppc64 ~sparc ~x86"
IUSE="emacs"

DEPEND="emacs? ( virtual/emacs )"
RDEPEND="${DEPEND}"

SITEFILE=50${PN}-gentoo.el

RUBY_PATCHES=(
	"${P}-pkgconfig.patch"
)

each_ruby_configure() {
	econf \
		--with-suikyo-docdir="/usr/share/doc/${PF}/html" \
		--with-rubydir="$(ruby_rbconfig_value 'sitelibdir')" || die
}

each_ruby_compile() {
	emake || die
}

each_ruby_install() {
	emake DESTDIR="${D}" install || die
}

all_ruby_install() {
	dodoc AUTHORS ChangeLog NEWS README || die

	if use emacs ; then
		elisp-site-file-install "${FILESDIR}/${SITEFILE}" || die
	else
		rm -rf "${D}"/usr/share/emacs/ || die
	fi
}

pkg_postinst() {
	use emacs && elisp-site-regen
}

pkg_postrm() {
	use emacs && elisp-site-regen
}
