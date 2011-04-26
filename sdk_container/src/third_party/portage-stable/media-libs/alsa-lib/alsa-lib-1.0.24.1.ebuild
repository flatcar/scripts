# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/alsa-lib/alsa-lib-1.0.24.1.ebuild,v 1.3 2011/02/17 17:26:29 sping Exp $

EAPI=3

PYTHON_DEPEND="python? 2"

inherit eutils libtool python multilib

MY_P=${P/_rc/rc}
S=${WORKDIR}/${MY_P}

DESCRIPTION="Advanced Linux Sound Architecture Library"
HOMEPAGE="http://www.alsa-project.org/"
SRC_URI="mirror://alsaproject/lib/${MY_P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-linux ~x86-linux"
IUSE="doc debug alisp python static-libs"

DEPEND=">=media-sound/alsa-headers-1.0.24
	doc? ( >=app-doc/doxygen-1.2.6 )"
RDEPEND=""

IUSE_PCM_PLUGIN="copy linear route mulaw alaw adpcm rate plug multi shm file
null empty share meter mmap_emul hooks lfloat ladspa dmix dshare dsnoop asym iec958
softvol extplug ioplug"

for plugin in ${IUSE_PCM_PLUGIN}; do
	IUSE="${IUSE} alsa_pcm_plugins_${plugin}"
done

pkg_setup() {
	if [ -z "${ALSA_PCM_PLUGINS}" ] ; then
		ewarn "You haven't selected _any_ PCM plugins. Either you set it to something like the default"
		ewarn "(which is being set in the profile UNLESS you unset them) or alsa based applications"
		ewarn "are going to *misbehave* !"
		epause 5
	fi

	if use python; then
		python_set_active_version 2
	fi
}

src_prepare() {
	elibtoolize
	epunt_cxx
}

src_configure() {
	local myconf
	use elibc_uclibc && myconf="--without-versioned"

	econf \
		$(use_enable static-libs static) \
		--enable-shared \
		--disable-resmgr \
		--enable-rawmidi \
		--enable-seq \
		--enable-aload \
		$(use_with debug) \
		$(use_enable alisp) \
		$(use_enable python) \
		--with-pcm-plugins="${ALSA_PCM_PLUGINS}" \
		--disable-dependency-tracking \
		${myconf}
}

src_compile() {
	emake || die

	if use doc; then
		emake doc || die "failed to generate docs"
		fgrep -Zrl "${S}" "${S}/doc/doxygen/html" | \
			xargs -0 sed -i -e "s:${S}::"
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die

	find "${ED}" -name '*.la' -exec rm -f {} +
	find "${ED}"/usr/$(get_libdir)/alsa-lib -name '*.a' -exec rm -f {} +

	dodoc ChangeLog TODO || die
	use doc && dohtml -r doc/doxygen/html/*
}

pkg_postinst() {
	elog "Please try in-kernel ALSA drivers instead of the alsa-driver ebuild."
	elog "If alsa-driver works for you where a *recent* kernel does not, we want "
	elog "to know about this. Our e-mail address is alsa-bugs@gentoo.org"
	elog "However, if you notice no sound output or instability, please try to "
	elog "upgrade your kernel to a newer version first."
}
