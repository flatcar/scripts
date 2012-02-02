# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/fox.eclass,v 1.8 2008/10/12 12:31:36 mabi Exp $

# fox eclass
#
# This eclass allows building SLOT-able FOX Toolkit installations
# (x11-libs/fox: headers, libs, and docs), which are by design
# parallel-installable, while installing only one version of the utils
# (dev-util/reswrap) and apps (app-editors/adie, sci-calculators/calculator,
# x11-misc/pathfinder, and x11-misc/shutterbug).
#
# Version numbering follows the kernel-style odd-even minor version
# designation.  Even-number minor versions are API stable, which patch
# releases aimed mostly at the library; apps generally won't need to be
# bumped for a patch release.
#
# Odd-number versions are development branches with their own SLOT and
# are API unstable; changes are made to the apps, and likely need to be
# bumped together with the library.
#
# Here are sample [R]DEPENDs for the fox apps
# fox versions that do not use this eclass are blocked in INCOMPAT_DEP below
#	1.0: '=x11-libs/fox-1.0*'
#	1.2: '=x11-libs/fox-1.2*'
#	1.4: '=x11-libs/fox-1.4*'
#	1.5: '~x11-libs/fox-${PV}'
#	1.6: '=x11-libs/fox-${FOXVER}*'
#
# Some concepts borrowed from gst-plugins and gtk-sharp-component eclasses

inherit eutils libtool versionator


FOX_PV="${FOX_PV:-${PV}}"
PVP=(${FOX_PV//[-\._]/ })
FOXVER="${PVP[0]}.${PVP[1]}"

if [ "${FOXVER}" != "1.0" ] ; then
	FOXVER_SUFFIX="-${FOXVER}"
fi

DESCRIPTION="C++ based Toolkit for developing Graphical User Interfaces easily and effectively"
HOMEPAGE="http://www.fox-toolkit.org/"
SRC_URI="http://www.fox-toolkit.org/ftp/fox-${FOX_PV}.tar.gz"

IUSE="debug doc profile"

# from fox-1.0
FOX_APPS="adie calculator pathfinder"
# from fox-1.2+
if [ "${FOXVER}" != "1.0" ] ; then
	FOX_APPS="${FOX_APPS} shutterbug"
	FOX_CHART="chart"
fi

if [ "${PN}" != fox ] ; then
	FOX_COMPONENT="${FOX_COMPONENT:-${PN}}"
fi

if [ "${FOXVER}" != "1.0" ] && [ -z "${FOX_COMPONENT}" ] ; then
	DOXYGEN_DEP="doc? ( app-doc/doxygen )"
fi

if [ "${PN}" != reswrap ] ; then
	RESWRAP_DEP="dev-util/reswrap"
fi

# These versions are not compatible with new fox layout
# and will cause collissions - we need to block them
INCOMPAT_DEP="!<x11-libs/fox-1.0.53
	!=x11-libs/fox-1.2.4
	!~x11-libs/fox-1.2.6
	!=x11-libs/fox-1.4.11"

DEPEND="${INCOMPAT_DEP}
	${DOXYGEN_DEP}
	${RESWRAP_DEP}
	=sys-devel/automake-1.4*
	>=sys-apps/sed-4"

S="${WORKDIR}/fox-${FOX_PV}"

fox_src_unpack() {
	unpack ${A}
	cd ${S}

	ebegin "Fixing configure"

	# Respect system CXXFLAGS
	sed -i -e 's:CXXFLAGS=""::' configure.in || die "sed configure.in error"
	touch aclocal.m4
	sed -i -e 's:CXXFLAGS=""::' configure || die "sed configure error"

	eend

	ebegin "Fixing Makefiles"

	# don't build apps from top-level (i.e. x11-libs/fox)
	# utils == reswrap
	for d in ${FOX_APPS} utils windows ; do
		sed -i -e "s:${d}::" Makefile.am || die "sed Makefile.am error"
	done

	# use the installed reswrap for everything else
	for d in ${FOX_APPS} ${FOX_CHART} tests ; do
		sed -i -e 's:$(top_builddir)/utils/reswrap:reswrap:' \
			${d}/Makefile.am || die "sed ${d}/Makefile.am error"
	done

	# use the installed headers and library for apps
	for d in ${FOX_APPS} ; do
		if version_is_at_least "1.6.34" ${PV} ; then
			sed -i \
				-e "s:-I\$(top_srcdir)/include -I\$(top_builddir)/include:-I\$(includedir)/fox${FOXVER_SUFFIX}:" \
				-e 's:$(top_builddir)/src/libFOX:-lFOX:' \
				-e 's:\.la::' \
				${d}/Makefile.am || die "sed ${d}/Makefile.am error"
		else
			sed -i \
				-e "s:-I\$(top_srcdir)/include -I\$(top_builddir)/include:-I\$(includedir)/fox${FOXVER_SUFFIX}:" \
				-e 's:../src/libFOX:-lFOX:' \
				-e 's:\.la::' \
				${d}/Makefile.am || die "sed ${d}/Makefile.am error"
		fi
	done

	# Upstream often has trouble with version number transitions
	if [ "${FOXVER}" == "1.5" ] ; then
		sed -i -e 's:1.4:1.5:g' chart/Makefile.am
	fi

	eend

	ebegin "Running automake"
	automake-1.4 -a -c || die "automake error"
	eend

	elibtoolize
}

fox_src_compile() {
	local myconf
	use debug && myconf="${myconf} --enable-debug" \
		|| myconf="${myconf} --enable-release"

	econf \
		${FOXCONF} \
		${myconf} \
		$(use_with profile profiling) \
		|| die "configure error"

	cd ${S}/${FOX_COMPONENT}
	emake || die "compile error"

	# build class reference docs (FOXVER >= 1.2)
	if use doc && [ "${FOXVER}" != "1.0" ] && [ -z "${FOX_COMPONENT}" ] ; then
		cd ${S}/doc
		make docs || die "doxygen error"
	fi
}

fox_src_install () {
	cd ${S}/${FOX_COMPONENT}

	make install \
		DESTDIR=${D} \
		htmldir=/usr/share/doc/${PF}/html \
		artdir=/usr/share/doc/${PF}/html/art \
		screenshotsdir=/usr/share/doc/${PF}/html/screenshots \
		|| die "install error"

	# create desktop menu items for apps
	case ${FOX_COMPONENT} in
		adie)
			newicon big_gif.gif adie.gif
			make_desktop_entry adie "Adie Text Editor" adie.gif
			;;
		calculator)
			newicon bigcalc.gif foxcalc.gif
			make_desktop_entry calculator "FOX Calculator" foxcalc.gif
			;;
		pathfinder)
			newicon iconpath.gif pathfinder.gif
			make_desktop_entry PathFinder "PathFinder" pathfinder.gif "FileManager"
			;;
		shutterbug)
			doicon shutterbug.gif
			make_desktop_entry shutterbug "ShutterBug" shutterbug.gif "Graphics"
			;;
	esac

	for doc in ADDITIONS AUTHORS LICENSE_ADDENDUM README TRACING ; do
		[ -f $doc ] && dodoc $doc
	done

	# remove documentation if USE=-doc
	if ( ! use doc ) && [ -d ${D}/usr/share/doc/${PF}/html ] ; then
		rm -fr ${D}/usr/share/doc/${PF}/html
	fi

	# install class reference docs (FOXVER >= 1.2) if USE=doc
	if use doc && [ "${FOXVER}" != "1.0" ] && [ -z "${FOX_COMPONENT}" ] ; then
		dohtml -r ${S}/doc/ref
	fi

	# slot fox-config where present (FOXVER >= 1.2)
	if [ -f ${D}/usr/bin/fox-config ] ; then
		mv ${D}/usr/bin/fox-config ${D}/usr/bin/fox-${FOXVER}-config
	fi
}

fox_pkg_postinst() {
	if [ -z "${FOX_COMPONENT}" ] ; then
		echo
		einfo "Multiple versions of the FOX Toolkit library may now be installed"
		einfo "in parallel SLOTs on the same system."
		einfo
		einfo "The reswrap utility and the applications included in the FOX Toolkit"
		einfo "(adie, calculator, pathfinder, shutterbug) are now available as"
		einfo "separate ebuilds."
		echo
		if [ "${FOXVER}" != "1.0" ] ; then
			einfo "The fox-config script has been installed as fox-${FOXVER}-config."
			einfo "The fox-wrapper package is used to direct calls to fox-config"
			einfo "to the correct versioned script, based on the WANT_FOX variable."
			einfo "For example:"
			einfo
			einfo "    WANT_FOX=\"${FOXVER}\" fox-config <options>"
			einfo
			epause
		fi
	fi
}

EXPORT_FUNCTIONS src_unpack src_compile src_install pkg_postinst
