# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libbs2b/libbs2b-3.1.0.ebuild,v 1.10 2012/05/05 08:02:25 jdhore Exp $

DESCRIPTION="Bauer stereophonic-to-binaural DSP library"
HOMEPAGE="http://bs2b.sourceforge.net/"
SRC_URI="mirror://sourceforge/bs2b/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 hppa ppc ppc64 sparc x86 ~x86-fbsd"
IUSE=""

RDEPEND="media-libs/libsndfile"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_install()
{
	emake install DESTDIR="${D}" || die "emake install failed"
}
