# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/suikyo/suikyo-2.1.0-r3.ebuild,v 1.3 2011/12/02 22:34:32 hwoarang Exp $

EAPI="2"
USE_RUBY="ruby18"
inherit elisp-common eutils multilib ruby-ng

DESCRIPTION="Romaji Hiragana conversion library"
HOMEPAGE="http://taiyaki.org/suikyo/"
SRC_URI="http://prime.sourceforge.jp/src/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 ~hppa ~ppc ~ppc64 ~sparc x86"
IUSE="emacs"

DEPEND="$(ruby_implementation_depend ruby18)
	emacs? ( virtual/emacs )"
RDEPEND="${DEPEND}"

SITEFILE=50${PN}-gentoo.el

src_unpack() {
	# prevent ruby-ng.eclass from messing with src_unpack
	default
}

src_prepare() {
	epatch "${FILESDIR}/${P}-pkgconfig.patch"
}

src_configure() {
	econf \
		--with-suikyo-docdir="/usr/share/doc/${PF}/html" \
		--with-rubydir="/usr/$(get_libdir)/ruby/site_ruby/1.8" || die
}

src_install() {
	emake DESTDIR="${D}" install || die

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
