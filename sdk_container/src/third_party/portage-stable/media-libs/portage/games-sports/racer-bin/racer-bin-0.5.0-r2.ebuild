# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-sports/racer-bin/racer-bin-0.5.0-r2.ebuild,v 1.1 2008/04/09 17:09:43 nyhm Exp $

inherit eutils games

DESCRIPTION="A car simulation game focusing on realism, in the style of Grand Prix Legends"
HOMEPAGE="http://www.racer.nl/"
SRC_URI="http://download.tdconline.dk/pub/boomtown/racesimcentral/rr_data${PV}.tgz
	http://download.tdconline.dk/pub/boomtown/racesimcentral/rr_bin_linux${PV}.tgz"

LICENSE="Racer"
SLOT="0"
KEYWORDS="-* x86"
RESTRICT="strip"
IUSE=""
QA_TEXTRELS=${GAMES_PREFIX_OPT:1}/${PN}/data/plugins/motion/move.so

DEPEND="=media-libs/fmod-3*"
RDEPEND="${DEPEND}
	virtual/opengl
	virtual/glu
	media-libs/libsdl
	sys-libs/lib-compat"

S=${WORKDIR}/racer${PV}

src_install() {
	local dir=${GAMES_PREFIX_OPT}/${PN}
	local f

	dodoc *.txt || die "dodoc failed"
	rm -f *.txt

	# Enable sound
	sed -i '222 s/0/1/' racer.ini || die "sed failed"

	insinto "${dir}"
	doins -r * || die "doins failed"

	for f in bin/* ; do
		games_make_wrapper ${f#*/} ${f} "${dir}" "${dir}"/bin
		fperms 750 "${dir}"/${f} || die "fperms ${f} failed"
	done

	local libfmod=$(find /usr/lib -maxdepth 1 -name 'libfmod-*so' -type f)
	dosym ${libfmod} "${dir}"/bin/libfmod-3.61.so
	dosym ${libfmod} "${dir}"/bin/libfmod-3.5.so

	# Fix up some permissions for bug 31694
	for f in racer.ini data/drivers/default/driver.ini \
		data/tracks/carlswood_nt/bestlaps.ini
	do
		fperms 660 "${dir}"/${f} || die "fperms ${f} failed"
	done

	make_desktop_entry racer Racer
	prepgamesdirs
}
