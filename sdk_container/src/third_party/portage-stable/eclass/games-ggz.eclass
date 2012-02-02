# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/games-ggz.eclass,v 1.5 2009/02/01 17:44:23 mr_bones_ Exp $

inherit base

# For GGZ Gaming Zone packages

case ${EAPI:-0} in
	0|1) EXPORT_FUNCTIONS src_compile src_install pkg_postinst pkg_postrm ;;
	2) EXPORT_FUNCTIONS src_configure src_compile src_install pkg_postinst pkg_postrm ;;
esac

HOMEPAGE="http://www.ggzgamingzone.org/"
SRC_URI="mirror://ggz/${PV}/${P}.tar.gz"

GGZ_MODDIR="/usr/share/ggz/modules"

games-ggz_src_configure() {
	econf \
		--disable-dependency-tracking \
		--enable-noregistry="${GGZ_MODDIR}" \
		$(has debug ${IUSE} && ! use debug && echo --disable-debug) \
		"$@" || die
}

games-ggz_src_compile() {
	case ${EAPI:-0} in
		0|1) games-ggz_src_configure "$@" ;;
	esac
	emake || die "emake failed"
}

games-ggz_src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	local f
	for f in AUTHORS ChangeLog NEWS QuickStart.GGZ README* TODO ; do
		[[ -f ${f} ]] && dodoc ${f}
	done
}

# Update ggz.modules with the .dsc files from ${GGZ_MODDIR}.
games-ggz_update_modules() {
	[[ ${EBUILD_PHASE} == "postinst" ]] || [[ ${EBUILD_PHASE} == "postrm" ]] \
	 	 || die "${FUNCNAME} can only be used in pkg_postinst or pkg_postrm"

	# ggz-config needs libggz, so it could be broken
	ggz-config -h &> /dev/null || return 1

	local confdir=${ROOT}/etc
	local moddir=${ROOT}/${GGZ_MODDIR}
	local dsc rval=0

	mkdir -p "${confdir}"
	echo -n > "${confdir}"/ggz.modules
	if [[ -d ${moddir} ]] ; then
		ebegin "Installing GGZ modules"
		cd "${moddir}"
		find . -type f -name '*.dsc' | while read dsc ; do
			DESTDIR=${ROOT} ggz-config -Dim "${dsc}" || ((rval++))
		done
		eend ${rval}
	fi
	return ${rval}
}

# Register new modules
games-ggz_pkg_postinst() {
	games-ggz_update_modules
}

# Unregister old modules
games-ggz_pkg_postrm() {
	games-ggz_update_modules
}
