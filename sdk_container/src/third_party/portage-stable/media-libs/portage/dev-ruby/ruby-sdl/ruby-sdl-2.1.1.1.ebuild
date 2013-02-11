# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/ruby-sdl/ruby-sdl-2.1.1.1.ebuild,v 1.4 2012/05/01 18:24:26 armin76 Exp $

EAPI=2
USE_RUBY="ruby18"

inherit eutils ruby-ng

MY_P="${P/-/}"
S="${WORKDIR}/${MY_P}"

DESCRIPTION="Ruby/SDL: Ruby bindings for SDL"
HOMEPAGE="http://www.kmc.gr.jp/~ohai/rubysdl.en.html"
SRC_URI="mirror://rubyforge/rubysdl/${MY_P}.tar.gz"
LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"

IUSE="image mixer truetype mpeg sge"

CDEPEND="
	>=media-libs/libsdl-1.2.5
	truetype? ( >=media-libs/sdl-ttf-2.0.6 )
	image? ( >=media-libs/sdl-image-1.2.2 )
	mixer? ( >=media-libs/sdl-mixer-1.2.4 )
	mpeg? ( >=media-libs/smpeg-0.4.4-r1 )
	sge? ( media-libs/sge )"
DEPEND="${DEPEND} ${CDEPEND}"
RDEPEND="${RDEPEND} ${CDEPEND}"

each_ruby_configure() {
	${RUBY} extconf.rb || die "extconf.rb failed"
}

each_ruby_compile() {
	emake || die "emake failed"
}

each_ruby_install() {
	emake DESTDIR="${D}" install || die "einstall failed"
}

all_ruby_install() {
	dodoc README.en README.ja NEWS.en NEWS.ja
	insinto /usr/share/doc/${P}/doc
	doins doc-en/*
	insinto /usr/share/doc/${P}/sample
	doins sample/*
}

pkg_postinst () {
	if ! use image || ! use mixer || ! use truetype || ! use mpeg || ! use sge; then
		echo ""
		ewarn "If any of the following packages are not installed, Ruby/SDL"
		ewarn "will be missing some functionality. This is ok, but may"
		ewarn "cause errors in Ruby/SDL programs that need these libraries:"
		ewarn ""
		ewarn "\tmedia-libs/sdl-image\tImage loading (PNG, JPEG, etc.)"
		ewarn "\tmedia-libs/sdl-mixer\tSound mixing"
		ewarn "\tmedia-libs/sdl-ttf\tTrueType Fonts"
		ewarn "\tmedia-libs/sge\t\tVarious cool graphics extensions"
		ewarn "\tmedia-libs/smpeg\tMPEG playback (including mp3)"
		ewarn ""
		ewarn "If you need the functionality offered by these libraries,"
		ewarn "emerge the desired libraries, then re-emerge dev-ruby/rubysdl"
		echo ""
	fi
}
