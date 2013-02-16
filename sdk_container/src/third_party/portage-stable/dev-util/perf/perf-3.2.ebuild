# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/perf/perf-3.2.ebuild,v 1.1 2012/02/28 22:21:05 vapier Exp $

EAPI="4"

PYTHON_DEPEND="python? 2"
inherit versionator eutils toolchain-funcs python linux-info

MY_PV="${PV/_/-}"
MY_PV="${MY_PV/-pre/-git}"

DESCRIPTION="Userland tools for Linux Performance Counters"
HOMEPAGE="http://perf.wiki.kernel.org/"

LINUX_V=$(get_version_component_range 1-2)

if [[ ${PV/_rc} != ${PV} ]] ; then
	LINUX_VER=$(get_version_component_range 1-2).$(($(get_version_component_range 3)-1))
	PATCH_VERSION=$(get_version_component_range 1-3)
	LINUX_PATCH=patch-${PV//_/-}.bz2
	SRC_URI="mirror://kernel/linux/kernel/v${LINUX_V}/testing/${LINUX_PATCH}
		mirror://kernel/linux/kernel/v${LINUX_V}/testing/v${PATCH_VERSION}/${LINUX_PATCH}"
elif [[ $(get_version_component_count) == 4 ]] ; then
	# stable-release series
	LINUX_VER=$(get_version_component_range 1-3)
	LINUX_PATCH=patch-${PV}.bz2
	SRC_URI="mirror://kernel/linux/kernel/v${LINUX_V}/${LINUX_PATCH}"
else
	LINUX_VER=${PV}
	SRC_URI=""
fi

LINUX_SOURCES="linux-${LINUX_VER}.tar.bz2"
SRC_URI+=" mirror://kernel/linux/kernel/v${LINUX_V}/${LINUX_SOURCES}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="+demangle +doc perl python slang"

RDEPEND="demangle? ( sys-devel/binutils )
	perl? ( || ( >=dev-lang/perl-5.10 sys-devel/libperl ) )
	slang? ( dev-libs/newt )
	dev-libs/elfutils"
DEPEND="${RDEPEND}
	${LINUX_PATCH+dev-util/patchutils}
	doc? ( app-text/asciidoc app-text/xmlto )"

S_K="${WORKDIR}/linux-${LINUX_VER}"
S="${S_K}/tools/perf"

CONFIG_CHECK="~PERF_EVENTS ~KALLSYMS"

pkg_setup() {
	use python && python_set_active_version 2
}

src_unpack() {
	local paths=( tools/perf include lib "arch/*/include" "arch/*/lib" )

	# We expect the tar implementation to support the -j option (both
	# GNU tar and libarchive's tar support that).
	echo ">>> Unpacking ${LINUX_SOURCES} (${paths[*]}) to ${PWD}"
	tar --wildcards -xpf "${DISTDIR}"/${LINUX_SOURCES} \
		"${paths[@]/#/linux-${LINUX_VER}/}" || die

	if [[ -n ${LINUX_PATCH} ]] ; then
		eshopts_push -o noglob
		ebegin "Filtering partial source patch"
		filterdiff -p1 ${paths[@]/#/-i } -z "${DISTDIR}"/${LINUX_PATCH} > ${P}.patch || die
		eend $? || die "filterdiff failed"
		eshopts_pop
	fi

	local a
	for a in ${A}; do
		[[ ${a} == ${LINUX_SOURCES} ]] && continue
		[[ ${a} == ${LINUX_PATCH} ]] && continue
		unpack ${a}
	done
}

src_prepare() {
	if [[ -n ${LINUX_PATCH} ]] ; then
		cd "${S_K}"
		epatch "${WORKDIR}"/${P}.patch
	fi

	# Drop some upstream too-developer-oriented flags and fix the
	# Makefile in general
	sed -i \
		-e 's:-Werror::' \
		-e 's:-ggdb3::' \
		-e 's:-fstack-protector-all::' \
		-e 's:^LDFLAGS =:EXTLIBS +=:' \
		-e '/\(PERL\|PYTHON\)_EMBED_LDOPTS/s:ALL_LDFLAGS +=:EXTLIBS +=:' \
		-e '/-x c - /s:\$(ALL_LDFLAGS):\0 $(EXTLIBS):' \
		-e '/^ALL_CFLAGS =/s:$: $(CFLAGS_OPTIMIZE):' \
		-e '/^ALL_LDFLAGS =/s:$: $(LDFLAGS_OPTIMIZE):' \
		-e '/.FORCE-PERF-VERSION-FILE/s,.FORCE-PERF-VERSION-FILE,,g' \
		"${S}"/Makefile

	# Avoid the call to make kernelversion
	echo "PERF_VERSION = ${MY_PV}" > PERF-VERSION-FILE

	# The code likes to compile local assembly files which lack ELF markings.
	find -name '*.S' -exec sed -i '$a.section .note.GNU-stack,"",%progbits' {} +
}

puse() { usex $1 "" no; }
perf_make() {
	emake V=1 \
		CC="$(tc-getCC)" AR="$(tc-getAR)" \
		prefix="/usr" bindir_relative="sbin" \
		CFLAGS_OPTIMIZE="${CFLAGS}" \
		LDFLAGS_OPTIMIZE="${LDFLAGS}" \
		ARCH="$(tc-arch-kernel)" \
		NO_DEMANGLE=$(puse demangle) \
		NO_LIBPERL=$(puse perl) \
		NO_LIBPYTHON=$(puse python) \
		NO_NEWT=$(puse slang) \
		"$@"
}

src_compile() {
	perf_make

	if use doc ; then
		pushd Documentation
		emake ${makeargs}
		popd
	fi
}

src_test() {
	:
}

src_install() {
	perf_make install DESTDIR="${D}"

	dodoc CREDITS

	dodoc *txt Documentation/*.txt
	if use doc ; then
		dohtml Documentation/*.html
		doman Documentation/*.1
	fi
}

pkg_postinst() {
	if ! use doc ; then
		elog "Without the doc USE flag you won't get any documentation nor man pages."
		elog "And without man pages, you won't get any --help output for perf and its"
		elog "sub-tools."
	fi
}
