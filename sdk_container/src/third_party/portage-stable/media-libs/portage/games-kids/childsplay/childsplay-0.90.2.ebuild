# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-kids/childsplay/childsplay-0.90.2.ebuild,v 1.5 2012/04/12 07:21:10 tupone Exp $

EAPI=3
PYTHON_DEPEND="2"
inherit eutils python games

DESCRIPTION="A suite of educational games for young children"
HOMEPAGE="http://childsplay.sourceforge.net/"
PLUGINS_VERSION="0.90"
PLUGINS_LFC_VERSION="0.90"
SRC_URI="mirror://sourceforge/childsplay/${P}.tgz
	mirror://sourceforge/childsplay/${PN}_plugins-${PLUGINS_VERSION}.tgz
	mirror://sourceforge/childsplay/${PN}_plugins_lfc-${PLUGINS_LFC_VERSION}.tgz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 x86"
IUSE=""

DEPEND=">=dev-python/pygame-1.7.1
	>=media-libs/sdl-image-1.2[gif,jpeg,png]
	>=media-libs/sdl-ttf-2.0
	>=media-libs/sdl-mixer-1.2[vorbis]
	media-libs/libogg"

pkg_setup() {
	python_set_active_version 2
	games_pkg_setup
}

src_prepare() {
	local DIR

	# Copy the plugins into the main package.
	mv ../${PN}_plugins-${PLUGINS_VERSION}/Data/AlphabetSounds Data || die
	mv ../${PN}_plugins-${PLUGINS_VERSION}/add-score.py . || die
	for DIR in ${PN}_plugins-${PLUGINS_VERSION} ${PN}_plugins_lfc-${PLUGINS_LFC_VERSION}; do
		mv ../${DIR}/Data/*.icon.png Data/icons || die
		cp -r ../${DIR}/lib/* lib || die
		mv ../${DIR}/assetml/${PN}/* assetml/${PN} || die
		rm -rf ../${DIR}
	done
	gunzip man/childsplay.6.gz
	epatch "${FILESDIR}"/${P}-gentoo.patch \
		|| die "epatch failed"
	python_convert_shebangs -r 2 .
}

src_install() {
	local fn

	# The following variables are based on Childsplay's INSTALL.sh
	_LOCALEDIR=/usr/share/locale
	_ASSETMLDIR=/usr/share/assetml
	_SCOREDIR=${GAMES_STATEDIR}
	_SCOREFILE=${_SCOREDIR}/childsplay.score
	_CPDIR=$(games_get_libdir)/childsplay
	_SHAREDIR=${GAMES_DATADIR}/childsplay
	_LIBDIR=${_CPDIR}/lib
	_MODULESDIR=${_LIBDIR}
	_SHARELIBDATADIR=${_SHAREDIR}/lib
	_SHAREDATADIR=${_SHAREDIR}/Data
	_RCDIR=${_SHARELIBDATADIR}/ConfigData
	_HOME_DIR_NAME=.childsplay
	_CHILDSPLAYRC=childsplayrc

	dodir \
		"${_CPDIR}" \
		"${_LIBDIR}" \
		"${_SHAREDIR}" \
		"${_SHARELIBDATADIR}" \
		"${_SCOREDIR}" \
		"${_LOCALEDIR}" \
		"${_ASSETMLDIR}"

	# create BASEPATH.py
	cat >BASEPATH.py <<EOF
## Automated file--please do not edit
LOCALEDIR="${_LOCALEDIR}"
ASSETMLDIR="${_ASSETMLDIR}"
SCOREDIR="${_SCOREDIR}"
SCOREFILE="${_SCOREFILE}"
CPDIR="${_CPDIR}"
SHAREDIR="${_SHAREDIR}"
LIBDIR="${_LIBDIR}"
MODULESDIR="${_MODULESDIR}"
SHARELIBDATADIR="${_SHARELIBDATADIR}"
SHAREDATADIR="${_SHAREDATADIR}"
RCDIR="${_RCDIR}"
HOME_DIR_NAME="${_HOME_DIR_NAME}"
CHILDSPLAYRC="${_CHILDSPLAYRC}"
EOF

	# copy software and data
	cp -r *.py "${D}/${_CPDIR}" || die "cp failed"
	cp -r Data "${D}/${_SHAREDIR}" || die "cp failed"
	rm "${D}/${_SHAREDIR}/Data/childsplay.score"  # this copy won't be used

	for fn in $(ls lib); do
		if [[ -d lib/${fn} ]] ; then
			cp -r lib/${fn} "${D}/${_SHARELIBDATADIR}" || die
		else
			cp lib/${fn} "${D}/${_LIBDIR}" || die
		fi
	done

	if [[ ${LINGUAS+set} ]]; then
		for lang in $LINGUAS; do
			[[ -d locale/$lang ]] && cp -r locale/$lang "${D}/${_LOCALEDIR}"
		done
	else
		cp -r locale/* "${D}/${_LOCALEDIR}" || die
	fi
	cp -r assetml/* "${D}/${_ASSETMLDIR}" || die

	# initialize the score file
	cp Data/childsplay.score "${D}/${_SCOREFILE}" || die
	SCORE_GAMES="Packid,Numbers,Soundmemory,Fallingletters,Findsound,Findsound2,Billiard"
	$(PYTHON) add-score.py "${D}/${_SCOREDIR}" $SCORE_GAMES

	# translate for the letters game
	$(PYTHON) letters-trans.py "${D}/${_ASSETMLDIR}"

	doman man/childsplay.6
	dodoc doc/README* doc/Changelog doc/copyright

	# Make a launcher.
	dogamesbin "${FILESDIR}"/childsplay || die
	sed -i \
		-e "s:GENTOO_DIR:${_CPDIR}:" \
		-e "s:python:$(PYTHON):" \
		"${D}${GAMES_BINDIR}"/childsplay \
		|| die "sed failed"

	newicon assetml/childsplay/childsplay-images/chpl-icon-48.png ${PN}.png
	make_desktop_entry childsplay Childsplay

	prepgamesdirs
	fperms g+w "${_SCOREFILE}"
}

pkg_postinst() {
	python_mod_optimize "${_CPDIR}"
	games_pkg_postinst
}

pkg_postrm() {
	python_mod_cleanup "${_CPDIR}"
}
