# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Bumping notes: https://wiki.gentoo.org/wiki/Project:Toolchain/sys-libs/glibc
# Please read & adapt the page as necessary if obsolete.

PYTHON_COMPAT=( python3_{11..14} )
TMPFILES_OPTIONAL=1

EMULTILIB_PKG="true"

# Gentoo patchset (ignored for live ebuilds)
PATCH_VER=1
PATCH_DEV=dilfridge

# gcc mulitilib bootstrap files version
GCC_BOOTSTRAP_VER=20201208

# systemd integration version
GLIBC_SYSTEMD_VER=20210729

# Minimum kernel version that glibc requires
MIN_KERN_VER="3.2.0"

# Minimum pax-utils version needed (which contains any new syscall changes for
# its seccomp filter!). Please double check this!
MIN_PAX_UTILS_VER="1.3.3"

# Minimum systemd version needed (which contains any new syscall changes for
# its seccomp filter!). Please double check this!
MIN_SYSTEMD_VER="254.9-r1"

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/glibc.asc

inherit python-any-r1 prefix preserve-libs toolchain-funcs flag-o-matic gnuconfig \
	multilib systemd multiprocessing tmpfiles eapi9-ver verify-sig

DESCRIPTION="GNU libc C library"
HOMEPAGE="https://www.gnu.org/software/libc/"

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
else
	KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86"
	SRC_URI="mirror://gnu/glibc/${P}.tar.xz"
	SRC_URI+=" https://distfiles.gentoo.org/pub/proj/toolchain/glibc/patches/${P}-patches-${PATCH_VER}.tar.xz"
	SRC_URI+=" verify-sig? ( mirror://gnu/glibc/${P}.tar.xz.sig )"
fi

SRC_URI+=" multilib-bootstrap? ( https://dev.gentoo.org/~dilfridge/distfiles/gcc-multilib-bootstrap-${GCC_BOOTSTRAP_VER}.tar.xz )"
SRC_URI+=" systemd? ( https://gitweb.gentoo.org/proj/toolchain/glibc-systemd.git/snapshot/glibc-systemd-${GLIBC_SYSTEMD_VER}.tar.gz )"

LICENSE="LGPL-2.1+ BSD HPND ISC inner-net rc PCRE"
SLOT="2.2"
IUSE="audit caps cet clang compile-locales custom-cflags doc gd hash-sysv-compat headers-only +multiarch multilib multilib-bootstrap nscd perl profile selinux sframe +ssp stack-realign +static-libs suid systemd systemtap test vanilla"

# Here's how the cross-compile logic breaks down ...
#  CTARGET - machine that will target the binaries
#  CHOST   - machine that will host the binaries
#  CBUILD  - machine that will build the binaries
# If CTARGET != CHOST, it means you want a libc for cross-compiling.
# If CHOST != CBUILD, it means you want to cross-compile the libc.
#  CBUILD = CHOST = CTARGET    - native build/install
#  CBUILD != (CHOST = CTARGET) - cross-compile a native build
#  (CBUILD = CHOST) != CTARGET - libc for cross-compiler
#  CBUILD != CHOST != CTARGET  - cross-compile a libc for a cross-compiler
# For install paths:
#  CHOST = CTARGET  - install into /
#  CHOST != CTARGET - install into /usr/CTARGET/
#
export CBUILD=${CBUILD:-${CHOST}}
export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY} == cross-* ]] ; then
		export CTARGET=${CATEGORY#cross-}
	fi
fi

# Note [Disable automatic stripping]
# Disabling automatic stripping for a few reasons:
# - portage's attempt to strip breaks non-native binaries at least on
#   arm: bug #697428
# - portage's attempt to strip libpthread.so.0 breaks gdb thread
#   enumeration: bug #697910. This is quite subtle:
#   * gdb uses glibc's libthread_db-1.0.so to enumerate threads.
#   * libthread_db-1.0.so needs access to libpthread.so.0 local symbols
#     via 'ps_pglobal_lookup' symbol defined in gdb.
#   * 'ps_pglobal_lookup' uses '.symtab' section table to resolve all
#     known symbols in 'libpthread.so.0'. Specifically 'nptl_version'
#     (unexported) is used to sanity check compatibility before enabling
#     debugging.
#     Also see https://sourceware.org/gdb/wiki/FAQ#GDB_does_not_see_any_threads_besides_the_one_in_which_crash_occurred.3B_or_SIGTRAP_kills_my_program_when_I_set_a_breakpoint
#   * normal 'strip' command trims '.symtab'
#   Thus our main goal here is to prevent 'libpthread.so.0' from
#   losing it's '.symtab' entries.
# - similarly, valgrind requires knowledge about symbols in ld.so:
#	bug #920753
# As Gentoo's strip does not allow us to pass less aggressive stripping
# options and does not check the machine target we strip selectively.

# We need a new-enough binutils/gcc to match upstream baseline.
# Also we need to make sure our binutils/gcc supports TLS,
# and that gcc already contains the hardened patches.
# Lastly, let's avoid some openssh nastiness, bug 708224, as
# convenience to our users.

IDEPEND="
	!compile-locales? ( sys-apps/locale-gen )
"
BDEPEND="
	${PYTHON_DEPS}
	>=app-misc/pax-utils-${MIN_PAX_UTILS_VER}
	sys-devel/bison
	compile-locales? ( sys-apps/locale-gen )
	doc? (
		dev-lang/perl
		sys-apps/texinfo
	)
	sframe? ( >=sys-devel/binutils-2.45 )
	test? (
		dev-lang/perl
		>=net-dns/libidn2-2.3.0
		sys-apps/gawk[mpfr]
	)
	verify-sig? ( sec-keys/openpgp-keys-glibc )
"
COMMON_DEPEND="
	gd? ( media-libs/gd:2= )
	nscd? ( selinux? (
		audit? ( sys-process/audit )
		caps? ( sys-libs/libcap )
	) )
	suid? ( caps? ( sys-libs/libcap ) )
	selinux? ( sys-libs/libselinux )
	systemtap? ( dev-debug/systemtap )
"
DEPEND="${COMMON_DEPEND}
"
RDEPEND="${COMMON_DEPEND}
	!<app-misc/pax-utils-${MIN_PAX_UTILS_VER}
	!<sys-apps/systemd-${MIN_SYSTEMD_VER}
	perl? ( dev-lang/perl )
"

RESTRICT="!test? ( test )"

if [[ ${CATEGORY} == cross-* ]] ; then
	BDEPEND+=" !headers-only? (
		>=${CATEGORY}/binutils-2.27
		>=${CATEGORY}/gcc-6.2
	)"

	case ${CATEGORY} in
		*-linux*)
			DEPEND+=" ${CATEGORY}/linux-headers"
			;;
		*-gnu)
			DEPEND+=" ${CATEGORY}/gnumach[-headers-only]"
			;;
	esac
else
	BDEPEND+="
		>=sys-devel/binutils-2.27
		clang? ( || ( ( >=sys-devel/gcc-6.2 )
			( >=sys-devel/gcc-6.2 >=llvm-core/clang-18 )
			( >=llvm-runtimes/libgcc-18 ) ) )
		!clang? ( >=sys-devel/gcc-6.2 )
	"
	DEPEND+=" virtual/os-headers "
	RDEPEND+="
		>=net-dns/libidn2-2.3.0
		vanilla? ( !sys-libs/timezone-data )
	"
	PDEPEND+=" !vanilla? ( sys-libs/timezone-data )"
fi

# Ignore tests whitelisted below
GENTOO_GLIBC_XFAIL_TESTS="${GENTOO_GLIBC_XFAIL_TESTS:-yes}"

XFAIL_TEST_LIST=(
	tst-support_descriptors
	tst-system
	tst-strerror
	tst-strsignal
	tst-sched1
	tst-sched_setattr
	tst-sched_setattr-thread
	tst-valgrind-smoke
	tst-shstk-legacy-1g
	test-double-compoundn
	test-float-compoundn
	test-float32-compoundn
	test-float32x-compoundn
	test-float64-compoundn
	tst-setvbuf2
)

XFAIL_NSPAWN_TEST_LIST=(
	test-errno-linux
	tst-aarch64-pkey
	tst-bz21269
	tst-mlock2
	tst-mseal-pkey
	tst-ntp_gettime
	tst-ntp_gettime-time64
	tst-ntp_gettimex
	tst-ntp_gettimex-time64
	tst-pkey
	tst-process_mrelease
	tst-adjtime
	tst-adjtime-time64
	tst-clock2
	tst-clock2-time64
	tst-sync_file_range
	test-errno
)

dump_build_environment() {
	einfo ==== glibc build environment ========================================================
	local v
	for v in ABI CBUILD CHOST CTARGET CBUILD_OPT CTARGET_OPT CC CXX CPP LD \
		{AS,C,CPP,CXX,LD}FLAGS MAKEINFO NM AR AS STRIP RANLIB OBJCOPY \
		STRINGS OBJDUMP READELF; do
		einfo " $(printf '%15s' ${v}:)   ${!v}"
	done
	einfo =====================================================================================
}

is_crosscompile() {
	[[ ${CHOST} != ${CTARGET} ]]
}

is_linux() {
	[[ ${CTARGET} == *-linux-* ]]
}

is_hurd() {
	[[ ${CTARGET} != *-linux-* ]]
}

just_headers() {
	is_crosscompile && use headers-only
}

alt_prefix() {
	is_crosscompile && echo /usr/${CTARGET}
}

host_eprefix() {
	is_crosscompile || echo "${EPREFIX}"
}

build_eprefix() {
	is_crosscompile && echo "${EPREFIX}"
}

alt_headers() {
	echo $(alt_prefix)/usr/include
}
alt_libdir() {
	echo $(alt_prefix)/$(get_libdir)
}
alt_usrlibdir() {
	echo $(alt_prefix)/usr/$(get_libdir)
}

builddir() {
	echo "${WORKDIR}/build-${ABI}-${CTARGET}-$1"
}

do_compile_test() {
	local ret save_cflags=${CFLAGS}
	CFLAGS+=" $1"
	shift

	pushd "${T}" >/dev/null

	rm -f glibc-test*
	printf '%b' "$*" > glibc-test.c

	nonfatal emake glibc-test
	ret=$?

	popd >/dev/null

	CFLAGS=${save_cflags}
	return ${ret}
}

do_run_test() {
	local ret

	if [[ ${MERGE_TYPE} == "binary" ]] ; then
		CC="${glibc__ORIG_CC}" CXX="${glibc__ORIG_CXX}" CPP="${glibc__ORIG_CPP}" \
			CFLAGS="-O2" LDFLAGS="" do_compile_test "" "$@" 2>/dev/null || return 0
	else
		ebegin "Performing simple compile test for ABI=${ABI}"
		if ! do_compile_test "" "$@" ; then
			ewarn "Simple build failed ... assuming this is desired #324685"
			eend 1
			return 0
		else
			eend 0
		fi
	fi

	pushd "${T}" >/dev/null

	./glibc-test
	ret=$?
	rm -f glibc-test*

	popd >/dev/null

	return ${ret}
}

setup_target_flags() {
	just_headers && return 0

	case $(tc-arch) in
		alpha)
			local cpu
			case $(get-flag mcpu) in
			21264a|ev67)           cpu="alphaev67" ;;
			21264|ev6)             cpu="alphaev6" ;;
			21164*|ev5|ev56|pca56) cpu="alphaev5" ;;
			esac
			[[ -n ${cpu} ]] && CTARGET_OPT="${cpu}-${CTARGET#*-}"
		;;
		x86)
			if ! do_compile_test "" 'void f(int i, void *p) {if (__sync_fetch_and_add(&i, 1)) f(i, p);}\nint main(){return 0;}\n'; then
				local t=${CTARGET_OPT:-${CTARGET}}
				t=${t%%-*}
				filter-flags '-march=*'
				export CFLAGS="-march=${t} ${CFLAGS}"
				einfo "Auto adding -march=${t} to CFLAGS #185404"
			fi
			use stack-realign && export CFLAGS+=" -mstackrealign"
		;;
		amd64)
			if [[ ${ABI} == x86 ]]; then
				if ! do_compile_test "${CFLAGS_x86}" 'void f(int i, void *p) {if (__sync_fetch_and_add(&i, 1)) f(i, p);}\nint main(){return 0;}\n'; then
					local t=${CTARGET_OPT:-${CTARGET}}
					t=${t%%-*}
					[[ ${t} == "x86_64" ]] && t="x86-64"
					filter-flags '-march=*'
					CFLAGS_x86=$(
						CFLAGS=${CFLAGS_x86}
						filter-flags '-march=*'
						is-flagq '-mfpmath=sse' && append-cflags -msse
						echo "${CFLAGS}"
					)
					export CFLAGS_x86="${CFLAGS_x86} -march=${t}"
					einfo "Auto adding -march=${t} to CFLAGS_x86 #185404 (ABI=${ABI})"
				fi
				use stack-realign && export CFLAGS_x86+=" -mstackrealign"
			fi

			if is_hurd ; then
				filter-flags '-march=*'
			fi
		;;
		mips)
			filter-ldflags -Wl,--hash-style=gnu -Wl,--hash-style=both
		;;
		ppc|ppc64)
			filter-flags '-mcpu=*'
		;;
		sparc)
			filter-flags "-fcall-used-g7"
			append-flags "-fcall-used-g6"

			local cpu
			case ${CTARGET} in
			sparc64-*)
				cpu="sparc64"
				case $(get-flag mcpu) in
				v9)
					append-flags "-Wa,-xarch=v9a"
					;;
				esac
				;;
			sparc-*)
				case $(get-flag mcpu) in
				v8|supersparc|hypersparc|leon|leon3)
					cpu="sparcv8"
					;;
				*)
					cpu="sparcv9"
					;;
				esac
			;;
			esac
			[[ -n ${cpu} ]] && CTARGET_OPT="${cpu}-${CTARGET#*-}"
		;;
	esac
}

setup_flags() {
	if is_crosscompile || tc-is-cross-compiler ; then
		CHOST=${CTARGET} strip-unsupported-flags
	fi

	CFLAGS_BASE=${CFLAGS_BASE-${CFLAGS}}
	CFLAGS=${CFLAGS_BASE}
	CXXFLAGS_BASE=${CXXFLAGS_BASE-${CXXFLAGS}}
	CXXFLAGS=${CXXFLAGS_BASE}
	ASFLAGS_BASE=${ASFLAGS_BASE-${ASFLAGS}}
	ASFLAGS=${ASFLAGS_BASE}

	if ! use custom-cflags; then
		strip-flags
		if ! is-flagq '-O@(2|3)' ; then
			filter-flags '-O?'
			append-flags -O2
		fi
	fi

	strip-unsupported-flags
	filter-lto
	filter-flags -m32 -m64 '-mabi=*'
	filter-ldflags '-Wl,-rpath=*'
	filter-ldflags '-Wl,--relax'
	filter-ldflags '-Wl,--dynamic-linker=*'
	filter-ldflags '-Wl,--gc-sections'

	if use hash-sysv-compat ; then
		append-ldflags '-Wl,--hash-style=both'
	fi

	append-flags -Wno-unused-command-line-argument
	filter-flags -frecord-gcc-switches
	filter-flags -fno-builtin
	filter-flags -fno-semantic-interposition
	filter-lfs-flags

	case ${CTARGET} in
		*-linux*)
			;;
		*-gnu)
			replace-flags -ggdb[3-9] -ggdb2
			replace-flags -g3 -g
			;;
	esac

	unset CBUILD_OPT CTARGET_OPT
	if use multilib ; then
		CTARGET_OPT=$(get_abi_CTARGET)
		[[ -z ${CTARGET_OPT} ]] && CTARGET_OPT=$(get_abi_CHOST)
	fi

	setup_target_flags

	if [[ -n ${CTARGET_OPT} && ${CBUILD} == ${CHOST} ]] && ! is_crosscompile; then
		CBUILD_OPT=${CTARGET_OPT}
	fi

	replace-flags -O0 -O1
	filter-flags '-fsanitize=*'
	filter-flags '-fcf-protection=*'

	if ! use cet; then
		case ${ABI}-${CTARGET} in
			amd64-x86_64-*|x32-x86_64-*-*-gnux32)
				append-flags '-fcf-protection=none'
				;;
			arm64-aarch64*)
				append-flags '-mbranch-protection=none'
				;;
		esac
	fi
}

use_multiarch() {
	use multiarch || return 1
	local bver nver
	bver=$($(tc-getLD ${CTARGET}) -v | sed -n -r '1{s:[^0-9]*::;s:^([0-9.]*).*:\1:;p}')
	case $(tc-arch ${CTARGET}) in
	amd64|x86) nver="2.20" ;;
	arm)       nver="2.22" ;;
	hppa)      nver="2.23" ;;
	ppc|ppc64) nver="2.20" ;;
	s390)      nver="2.24" ;;
	sparc)     nver="2.21" ;;
	*)         return 1 ;;
	esac
	ver_test ${bver} -ge ${nver}
}

setup_env() {
	unset LD_RUN_PATH
	unset LD_ASSUME_KERNEL

	if is_crosscompile || tc-is-cross-compiler ; then
		multilib_env ${CTARGET_OPT:-${CTARGET}}

		if ! use multilib ; then
			MULTILIB_ABIS=${DEFAULT_ABI}
		else
			MULTILIB_ABIS=${MULTILIB_ABIS:-${DEFAULT_ABI}}
		fi

		local VAR=CFLAGS_${CTARGET//[-.]/_}
		CFLAGS=${!VAR-${CFLAGS}}
		einfo " $(printf '%15s' 'Manual CFLAGS:')   ${CFLAGS}"
	fi

	setup_flags

	export ABI=${ABI:-${DEFAULT_ABI:-default}}

	if just_headers ; then
		einfo "Skip CC ABI injection. We can't use (cross-)compiler yet."
		return 0
	fi

	tc-ld-force-bfd

	if use doc ; then
		export MAKEINFO=makeinfo
	else
		export MAKEINFO=/dev/null
	fi

	export CC=${glibc__ORIG_CC:-${CC:-$(tc-getCC ${CTARGET})}}
	export CXX=${glibc__ORIG_CXX:-${CXX:-$(tc-getCXX ${CTARGET})}}
	export CPP=${glibc__ORIG_CPP:-${CPP:-$(tc-getCPP ${CTARGET})}}

	export glibc__ORIG_CC=${CC}
	export glibc__ORIG_CXX=${CXX}
	export glibc__ORIG_CPP=${CPP}

	if tc-is-clang && ! ( use clang || use custom-cflags ) && ! is_crosscompile ; then
		export glibc__force_gcc=yes
	fi

	if [[ ${glibc__force_gcc} == "yes" ]] ; then
		local current_binutils_path=$(env CHOST="${CBUILD}" ROOT="${BROOT}" binutils-config -B "${CTARGET}")
		local current_gcc_path=$(env ROOT="${BROOT}" gcc-config -B)
		einfo "Overriding clang configuration, since it won't work here"

		export CC="${current_gcc_path}/${CTARGET}-gcc"
		export CPP="${current_gcc_path}/${CTARGET}-cpp"
		export CXX="${current_gcc_path}/${CTARGET}-g++"
		export LD="${current_binutils_path}/ld.bfd"
		export AR="${current_binutils_path}/ar"
		export AS="${current_binutils_path}/as"
		export NM="${current_binutils_path}/nm"
		export STRIP="${current_binutils_path}/strip"
		export RANLIB="${current_binutils_path}/ranlib"
		export OBJCOPY="${current_binutils_path}/objcopy"
		export STRINGS="${current_binutils_path}/strings"
		export OBJDUMP="${current_binutils_path}/objdump"
		export READELF="${current_binutils_path}/readelf"
		export ADDR2LINE="${current_binutils_path}/addr2line"

		filter-flags '-fuse-ld=*'
		filter-flags '-D_FORTIFY_SOURCE=*'
	else
		export CC="$(tc-getCC ${CTARGET})"
		export CXX="$(tc-getCXX ${CTARGET})"
		export CPP="$(tc-getCPP ${CTARGET})"
		export NM="$(tc-getNM ${CTARGET})"
		export READELF="$(tc-getREADELF ${CTARGET})"
	fi

	export glibc__GLIBC_CC=${CC}
	export glibc__GLIBC_CXX=${CXX}
	export glibc__GLIBC_CPP=${CPP}

	export glibc__abi_CFLAGS="$(get_abi_CFLAGS)"

	export CC="${glibc__GLIBC_CC} ${glibc__abi_CFLAGS} ${CFLAGS} ${LDFLAGS}"
	export CXX="${glibc__GLIBC_CXX} ${glibc__abi_CFLAGS} ${CFLAGS}"
	export CPP="${glibc__GLIBC_CPP} ${glibc__abi_CFLAGS} ${CFLAGS}"

	if is_crosscompile; then
		export libc_cv_cxx_link_ok=no
		export CXX=
	fi
}

foreach_abi() {
	setup_env

	local ret=0
	local abilist=""
	if use multilib ; then
		abilist=$(get_install_abis)
	else
		abilist=${DEFAULT_ABI}
	fi
	local -x ABI
	for ABI in ${abilist:-default} ; do
		setup_env
		einfo "Running $1 for ABI ${ABI}"
		$1
		: $(( ret |= $? ))
	done
	return ${ret}
}

glibc_banner() {
	local b="Gentoo ${PVR}"
	[[ -n ${PATCH_VER} ]] && ! use vanilla && b+=" (patchset ${PATCH_VER})"
	echo "${b}"
}

g_get_running_KV() {
	uname -r
	return $?
}

g_KV_major() {
	echo "${1%%.*}"
}

g_KV_to_int() {
	local KV_major $(g_KV_major "$1")
	local KV_minor $(echo "$1" | cut -d. -f2)
	local KV_micro $(echo "$1" | cut -d. -f3 | sed -e 's:[^0-9].*::')
	echo $(( ${KV_major:-0} * 65536 + ${KV_minor:-0} * 256 + ${KV_micro:-0} ))
}

glibc_kv_int() {
	g_KV_to_int "${1:-$(g_get_running_KV)}"
}

pkg_pretend() {
	just_headers && return 0

	local min_kv=$(glibc_kv_int "${MIN_KERN_VER}")
	local run_kv=$(glibc_kv_int)

	if ver_test ${MIN_KERN_VER} -gt 3.2.0 ; then
		if [[ ${run_kv} -lt ${min_kv} ]] ; then
			ewarn "Running kernel version ${run_kv} is lower than required minimum ${MIN_KERN_VER}"
		fi
	fi
}

pkg_setup() {
	just_headers && return 0
	python-any-r1_pkg_setup
}

src_unpack() {
	if [[ ${PV} == *9999 ]]; then
		git-r3_src_unpack
	else
		verify-sig_src_unpack
	fi
}

src_prepare() {
	default
	gnuconfig_update
}

src_configure() {
	foreach_abi glibc_abi_configure
}

glibc_abi_configure() {
	local myconf=()

	if just_headers ; then
		myconf+=(
			--enable-hacker-mode
		)
	fi

	myconf+=(
		--prefix="$(host_eprefix)/usr"
		--sysconfdir="$(host_eprefix)/etc"
		--localstatedir="$(host_eprefix)/var"
		--libdir="$(host_eprefix)/usr/$(get_libdir)"
		--mandir="$(host_eprefix)/usr/share/man"
		--infodir="$(host_eprefix)/usr/share/info"
		--libexecdir="$(host_eprefix)/usr/libexec"
		--with-bugurl="https://bugs.gentoo.org/"
		--with-pkgversion="$(glibc_banner)"
		$(use_enable audit)
		$(use_enable caps)
		$(use_enable cet)
		$(use_enable multiarch)
		$(use_enable nscd)
		$(use_enable profile)
		$(use_enable selinux)
		$(use_enable sframe)
		$(use_enable systemtap)
	)

	mkdir -p "$(builddir)" || die
	cd "$(builddir)" || die

	echo "${S}/configure" "${myconf[@]}"
	"${S}/configure" "${myconf[@]}" || die "failed to configure glibc"
}

src_compile() {
	foreach_abi glibc_abi_compile
}

glibc_abi_compile() {
	cd "$(builddir)" || die
	emake
}

src_test() {
	foreach_abi glibc_abi_test
}

glibc_abi_test() {
	cd "$(builddir)" || die
	emake check
}

src_install() {
	foreach_abi glibc_abi_install
}

glibc_abi_install() {
	cd "$(builddir)" || die
	emake install_root="${ED}" install
}
