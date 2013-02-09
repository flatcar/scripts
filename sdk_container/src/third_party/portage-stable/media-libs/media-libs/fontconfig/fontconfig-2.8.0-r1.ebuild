# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/fontconfig/fontconfig-2.8.0-r1.ebuild,v 1.9 2012/05/05 08:02:34 jdhore Exp $

EAPI="2"

inherit autotools eutils libtool toolchain-funcs flag-o-matic

DESCRIPTION="A library for configuring and customizing font access"
HOMEPAGE="http://fontconfig.org/"
SRC_URI="http://fontconfig.org/release/${P}.tar.gz"

LICENSE="MIT"
SLOT="1.0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="doc"

# Purposefully dropped the xml USE flag and libxml2 support.  Expat is the
# default and used by every distro.  See bug #283191.

RDEPEND=">=media-libs/freetype-2.2.1
	>=dev-libs/expat-1.95.3"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? (
		app-text/docbook-sgml-utils[jadetex]
		=app-text/docbook-sgml-dtd-3.1*
	)"
PDEPEND="app-admin/eselect-fontconfig
	virtual/ttf-fonts"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2.7.1-latin-reorder.patch	# 130466
	epatch "${FILESDIR}"/${PN}-2.3.2-docbook.patch			# 310157
	epatch "${FILESDIR}"/${PN}-2.8.0-urw-aliases.patch		# 303591

	eautoreconf

	# Needed to get a sane .so versioning on fbsd, please dont drop
	# If you have to run eautoreconf, you can also leave the elibtoolize call as
	# it will be a no-op.
	elibtoolize
}

src_configure() {
	local myconf
	if tc-is-cross-compiler; then
		myconf="--with-arch=${ARCH}"
		replace-flags -mtune=* -DMTUNE_CENSORED
		replace-flags -march=* -DMARCH_CENSORED
	fi
	econf \
		$(use_enable doc docs) \
		$(use_enable doc docbook) \
		--localstatedir=/var \
		--with-default-fonts=/usr/share/fonts \
		--with-add-fonts=/usr/local/share/fonts \
		${myconf} || die
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install"
	emake DESTDIR="${D}" -C doc install-man || die "emake install-man"

	#fc-lang directory contains language coverage datafiles
	#which are needed to test the coverage of fonts.
	insinto /usr/share/fc-lang
	doins fc-lang/*.orth

	insinto /etc/fonts
	doins "${S}"/fonts.conf

	dodoc doc/fontconfig-user.{txt,pdf}
	dodoc AUTHORS ChangeLog README

	if [[ -e ${D}usr/share/doc/fontconfig/ ]];  then
		mv "${D}"usr/share/doc/fontconfig/* "${D}"/usr/share/doc/${P}
		rm -rf "${D}"usr/share/doc/fontconfig
	fi

	# Changes should be made to /etc/fonts/local.conf, and as we had
	# too much problems with broken fonts.conf, we force update it ...
	# <azarah@gentoo.org> (11 Dec 2002)
	echo 'CONFIG_PROTECT_MASK="/etc/fonts/fonts.conf"' > "${T}"/37fontconfig
	doenvd "${T}"/37fontconfig

	# As of fontconfig 2.7, everything sticks their noses in here.
	dodir /etc/sandbox.d
	echo 'SANDBOX_PREDICT="/var/cache/fontconfig"' > "${D}"/etc/sandbox.d/37fontconfig
}

pkg_preinst() {
	# Bug #193476
	# /etc/fonts/conf.d/ contains symlinks to ../conf.avail/ to include various
	# config files.  If we install as-is, we'll blow away user settings.
	ebegin "Syncing fontconfig configuration to system"
	if [[ -e ${ROOT}/etc/fonts/conf.d ]]; then
		for file in "${ROOT}"/etc/fonts/conf.avail/*; do
			f=${file##*/}
			if [[ -L ${ROOT}/etc/fonts/conf.d/${f} ]]; then
				[[ -f ${D}etc/fonts/conf.avail/${f} ]] \
					&& ln -sf ../conf.avail/"${f}" "${D}"etc/fonts/conf.d/ &>/dev/null
			else
				[[ -f ${D}etc/fonts/conf.avail/${f} ]] \
					&& rm "${D}"etc/fonts/conf.d/"${f}" &>/dev/null
			fi
		done
	fi
	eend $?
}

pkg_postinst() {
	einfo "Cleaning broken symlinks in "${ROOT}"etc/fonts/conf.d/"
	find -L "${ROOT}"etc/fonts/conf.d/ -type l -delete

	echo
	ewarn "Please make fontconfig configuration changes using \`eselect fontconfig\`"
	ewarn "Any changes made to /etc/fonts/fonts.conf will be overwritten."
	ewarn
	ewarn "If you need to reset your configuration to upstream defaults, delete"
	ewarn "the directory ${ROOT}etc/fonts/conf.d/ and re-emerge fontconfig."
	echo

	if [[ ${ROOT} = / ]]; then
		ebegin "Creating global font cache"
		/usr/bin/fc-cache -srf
		eend $?
	fi
}
