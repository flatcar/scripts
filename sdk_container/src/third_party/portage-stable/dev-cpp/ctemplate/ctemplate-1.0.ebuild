# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-cpp/ctemplate/ctemplate-1.0.ebuild,v 1.7 2012/05/24 19:27:18 vapier Exp $

EAPI="4"

inherit elisp-common python eutils

DESCRIPTION="A simple but powerful template language for C++"
HOMEPAGE="http://code.google.com/p/google-ctemplate/"
SRC_URI="http://google-ctemplate.googlecode.com/files/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 arm ~ppc x86 ~amd64-linux ~x86-linux"
IUSE="doc emacs vim-syntax static-libs test"

DEPEND="test? ( =dev-lang/python-2* )"
RDEPEND="vim-syntax? ( >=app-editors/vim-core-7 )
	emacs? ( virtual/emacs )"

SITEFILE="70ctemplate-gentoo.el"

pkg_setup() {
	if use test ; then
		python_set_active_version 2
		python_pkg_setup
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-gcc-4.7.patch
}

src_configure() {
	econf \
		--enable-shared \
		$(use_enable static-libs static)
}

src_compile() {
	default

	if use emacs ; then
		elisp-compile contrib/tpl-mode.el || die "elisp-compile failed"
	fi
}

src_install() {
	default

	# Installs just every piece
	rm -rf "${ED}/usr/share/doc"

	dodoc AUTHORS ChangeLog NEWS README
	use doc && dohtml doc/*

	if use vim-syntax ; then
		cd "${S}/contrib"
		sh highlighting.vim || die "unpacking vim scripts failed"
		insinto /usr/share/vim/vimfiles
		doins -r .vim/*
	fi

	if use emacs ; then
		cd "${S}/contrib"
		elisp-install ${PN} tpl-mode.el tpl-mode.elc || die "elisp-install failed"
		elisp-site-file-install "${FILESDIR}/${SITEFILE}"
	fi

	find "${ED}"/usr -name '*.la' -delete
}

pkg_postinst() {
	use emacs && elisp-site-regen
}

pkg_postrm() {
	use emacs && elisp-site-regen
}
