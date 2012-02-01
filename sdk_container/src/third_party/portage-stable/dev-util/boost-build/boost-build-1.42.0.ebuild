# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/boost-build/boost-build-1.42.0.ebuild,v 1.1 2010/03/03 12:32:08 djc Exp $

EAPI="2"

inherit flag-o-matic toolchain-funcs versionator

MY_PV=$(replace_all_version_separators _)
MAJOR_PV="$(replace_all_version_separators _ $(get_version_component_range 1-2))"

DESCRIPTION="A system for large project software construction, which is simple to use and powerful."
HOMEPAGE="http://www.boost.org/doc/tools/build/index.html"
SRC_URI="mirror://sourceforge/boost/boost_${MY_PV}.tar.bz2"
LICENSE="Boost-1.0"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="alpha amd64 arm hppa ia64 mips ppc ppc64 s390 sh sparc x86"
IUSE="examples python"

DEPEND="!<dev-libs/boost-1.34.0
	!<=dev-util/boost-build-1.35.0-r1
	python? ( dev-lang/python )"
RDEPEND="${DEPEND}"

S="${WORKDIR}/boost_${MY_PV}/tools"

pkg_setup() {
	ewarn "Compilation of boost-build is known to break if {C,LD}FLAGS contain"
	ewarn "extra white space (bug 293652)"
}

src_unpack() {
	tar xjpf "${DISTDIR}/${A}" boost_${MY_PV}/tools/{jam,build/v2} || die
}

src_prepare() {
	epatch "${FILESDIR}/boost-1.42-fix-mpich2-detection.patch"

	# Remove stripping option
	cd "${S}/jam/src"
	sed -i -e 's|-s\b||' \
		build.jam || die "sed failed"

	# Force regeneration
	rm jambase.c

	# This patch allows us to fully control optimization
	# and stripping flags when bjam is used as build-system
	# We simply extend the optimization and debug-symbols feature
	# with empty dummies called 'none'
	cd "${S}/build/v2"
	sed -i \
		-e 's/\(off speed space\)/\1 none/' \
		-e 's/\(debug-symbols      : on off\)/\1 none/' \
		tools/builtin.jam || die "sed failed"
}

src_compile() {
	cd jam/src
	local toolset

	if [[ ${CHOST} == *-darwin* ]] ; then
		toolset=darwin
	else
		# Using boost's generic toolset here, which respects CC and CFLAGS
		toolset=cc
	fi

	append-flags -fno-strict-aliasing

	# For slotting
	sed -i \
		-e "s|/usr/share/boost-build|/usr/share/boost-build-${MAJOR_PV}|" \
		Jambase || die "sed failed"

	# The build.jam file for building bjam using a bootstrapped jam0 ignores
	# the LDFLAGS env var (bug #209794). We have now two options:
	# a) change the cc-target definition in build.jam to include separate compile
	#    and link targets to make it use the LDFLAGS var, or
	# b) a simple dirty workaround by injecting the LDFLAGS in the LIBS env var
	#    (which should not be set by us).
	if [[ -z "${LDFLAGS}" ]] ; then
		CC=$(tc-getCC) ./build.sh ${toolset} $(use_with python) \
			|| die "building bjam failed"
	else
		LIBS=${LDFLAGS} CC=$(tc-getCC) ./build.sh ${toolset} \
			$(use_with python) || die "building bjam failed"
	fi
}

src_install() {
	newbin jam/src/bin.*/bjam bjam-${MAJOR_PV}

	cd "${S}/build/v2"
	insinto /usr/share/boost-build-${MAJOR_PV}
	doins -r boost-build.jam bootstrap.jam build-system.jam site-config.jam user-config.jam \
		build kernel options tools util || die

	dodoc changes.txt hacking.txt release_procedure.txt \
		notes/build_dir_option.txt notes/relative_source_paths.txt

	if use examples ; then
		insinto /usr/share/doc/${PF}
		doins -r example
	fi
}

src_test() {
	cd jam/test
	./test.sh || die "tests failed"
}
