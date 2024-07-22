# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

inherit toolchain-funcs flag-o-matic

code_ver=${PV}
data_ver=${PV}
DESCRIPTION="Timezone data (/usr/share/zoneinfo) and utilities (tzselect/zic/zdump)"
HOMEPAGE="https://www.iana.org/time-zones"
SRC_URI="https://www.iana.org/time-zones/repository/releases/tzdata${data_ver}.tar.gz
	https://www.iana.org/time-zones/repository/releases/tzcode${code_ver}.tar.gz"

LICENSE="BSD public-domain"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~x64-cygwin ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="nls leaps-timezone zic-slim"

DEPEND="nls? ( virtual/libintl )"
RDEPEND="${DEPEND}
	!sys-libs/glibc[vanilla(+)]"

src_unpack() {
	mkdir -p "${S}" && cd "${S}" || die
	default
}

src_prepare() {
	default

	# check_web contacts validator.w3.org
	sed -i -e 's/check_tables check_web/check_tables/g' \
		Makefile || die "Failed to disable check_web"

	tc-is-cross-compiler && cp -pR "${S}" "${S}"-native
}

src_configure() {
	tc-export CC

	append-lfs-flags #471102

	if use elibc_Darwin ; then
		append-cppflags -DSTD_INSPIRED #138251
	fi

	append-cppflags -DHAVE_GETTEXT=$(usex nls 1 0) -DTZ_DOMAIN='\"libc\"'

	# Upstream default is 'slim', but it breaks quite a few programs
	# that parse /etc/localtime directly: bug# 747538.
	append-cppflags -DZIC_BLOAT_DEFAULT='\"'$(usex zic-slim slim fat)'\"'

	LDLIBS=""
	if use nls ; then
		# See if an external libintl is available. #154181 #578424
		local c="${T}/test"
		echo 'main(){}' > "${c}.c"
		if $(tc-getCC) ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} "${c}.c" -o "${c}" -lintl 2>/dev/null ; then
			LDLIBS+=" -lintl"
		fi
	fi
}

_emake() {
	emake \
		REDO=$(usex leaps-timezone posix_right posix_only) \
		TOPDIR="${EPREFIX}" \
		ZICDIR='$(TOPDIR)/usr/bin' \
		"$@"
}

src_compile() {
	_emake \
		AR="$(tc-getAR)" \
		cc="$(tc-getCC)" \
		RANLIB="$(tc-getRANLIB)" \
		CFLAGS="${CFLAGS} -std=gnu99 ${CPPFLAGS}" \
		LDFLAGS="${LDFLAGS}" \
		LDLIBS="${LDLIBS}"
	if tc-is-cross-compiler ; then
		_emake -C "${S}"-native \
			AR="$(tc-getBUILD_AR)" \
			cc="$(tc-getBUILD_CC)" \
			RANLIB="$(tc-getBUILD_RANLIB)" \
			CFLAGS="${BUILD_CFLAGS} ${BUILD_CPPFLAGS}" \
			LDFLAGS="${BUILD_LDFLAGS}" \
			LDLIBS="${LDLIBS}" \
			zic
	fi
}

src_test() {
	# VALIDATE_ENV is used for extended/web based tests.  Punt on them.
	emake check VALIDATE_ENV=true
}

src_install() {
	local zic=""
	tc-is-cross-compiler && zic="zic=${S}-native/zic"
	_emake install ${zic} DESTDIR="${D}" LIBDIR="/nukeit"
	rm -rf "${D}/nukeit" "${ED}/etc" || die

	insinto /usr/share/zoneinfo
	doins "${S}"/leap-seconds.list

	# Delete man pages installed by man-pages package.
	rm "${ED}"/usr/share/man/man5/tzfile.5* "${ED}"/usr/share/man/man8/{tzselect,zdump,zic}.8 || die
	dodoc CONTRIBUTING README NEWS *.html

	# install the symlink by hand to not break existing timezones
	dosym . /usr/share/zoneinfo/posix
}
