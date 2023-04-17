# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="6"
WANT_LIBTOOL="none"

inherit autotools flag-o-matic pax-utils python-utils-r1 toolchain-funcs

MY_P="Python-${PV}"
PATCHSET_VERSION="3.6.4"

DESCRIPTION="An interpreted, interactive, object-oriented programming language"
HOMEPAGE="https://www.python.org/"
SRC_URI="https://www.python.org/ftp/python/${PV}/${MY_P}.tar.xz
	https://dev.gentoo.org/~floppym/python/python-gentoo-patches-${PATCHSET_VERSION}.tar.xz"

LICENSE="PSF-2"
SLOT="3.6/3.6m"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd"
IUSE="hardened"

# Do not add a dependency on dev-lang/python to this ebuild.
# If you need to apply a patch which requires python for bootstrapping, please
# run the bootstrap code on your dev box and include the results in the
# patchset. See bug 447752.

RDEPEND=""
DEPEND="app-arch/bzip2:0=
	app-arch/xz-utils:0=
	>=sys-libs/zlib-1.1.3:0=
	virtual/libintl
	!!<sys-apps/sandbox-2.6-r1
	virtual/pkgconfig
	!sys-devel/gcc[libffi(-)]"

S="${WORKDIR}/${MY_P}"
PYVER=${SLOT%/*}

src_prepare() {
	# Ensure that internal copies of zlib are not used.
	rm -fr Modules/zlib

	local PATCHES=(
		"${WORKDIR}/patches"
		"${FILESDIR}/python-3.5-distutils-OO-build.patch"
		"${FILESDIR}/3.6.5-disable-nis.patch"
		"${FILESDIR}/python-3.6.5-libressl-compatibility.patch"
		"${FILESDIR}/python-3.6.5-hash-unaligned.patch"
	)

	default

	sed -i -e "s:@@GENTOO_LIBDIR@@:$(get_libdir):g" \
		Lib/distutils/command/install.py \
		Lib/distutils/sysconfig.py \
		Lib/site.py \
		Lib/sysconfig.py \
		Lib/test/test_site.py \
		Makefile.pre.in \
		Modules/Setup.dist \
		Modules/getpath.c \
		configure.ac \
		setup.py || die "sed failed to replace @@GENTOO_LIBDIR@@"

	eautoreconf
}

src_configure() {
	local disable
	disable+=" gdbm"
	disable+=" _curses _curses_panel"
	disable+=" readline"
	disable+=" _sqlite3"
	export PYTHON_DISABLE_SSL="1"
	disable+=" _tkinter"
	export PYTHON_DISABLE_MODULES="${disable}"

	if [[ -n "${PYTHON_DISABLE_MODULES}" ]]; then
		einfo "Disabled modules: ${PYTHON_DISABLE_MODULES}"
	fi

	if [[ "$(gcc-major-version)" -ge 4 ]]; then
		append-flags -fwrapv
	fi

	filter-flags -malign-double

	# https://bugs.gentoo.org/show_bug.cgi?id=50309
	if is-flagq -O3; then
		is-flagq -fstack-protector-all && replace-flags -O3 -O2
		use hardened && replace-flags -O3 -O2
	fi

	if tc-is-cross-compiler; then
		# Force some tests that try to poke fs paths.
		export ac_cv_file__dev_ptc=no
		export ac_cv_file__dev_ptmx=yes
	fi

	# Export CXX so it ends up in /usr/lib/python3.X/config/Makefile.
	tc-export CXX

	# Set LDFLAGS so we link modules with -lpython3.2 correctly.
	# Needed on FreeBSD unless Python 3.2 is already installed.
	# Please query BSD team before removing this!
	append-ldflags "-L."

	local dbmliborder

	local myeconfargs=(
		--prefix=/usr/share/oem/python
		--with-fpectl
		--disable-shared
		--enable-ipv6
		--with-threads
		--includedir='/discard/include'
		--infodir='/discard/info'
		--mandir='/discard/man'
		--with-computed-gotos
		--with-dbmliborder="${dbmliborder}"
		--with-libc=
		--without-ensurepip
		--without-system-expat
		--without-system-ffi
	)

	OPT="" econf "${myeconfargs[@]}"

	if grep -q "#define POSIX_SEMAPHORES_NOT_ENABLED 1" pyconfig.h; then
		eerror "configure has detected that the sem_open function is broken."
		eerror "Please ensure that /dev/shm is mounted as a tmpfs with mode 1777."
		die "Broken sem_open function (bug 496328)"
	fi
}

src_compile() {
	# Ensure sed works as expected
	# https://bugs.gentoo.org/594768
	local -x LC_ALL=C

	emake CPPFLAGS= CFLAGS= LDFLAGS=
}

src_install() {
	local rawbindir=/usr/share/oem/python/bin
	local bindir=${ED}${rawbindir}
	local libdir=${ED}/usr/share/oem/python/$(get_libdir)/python${PYVER}

	emake DESTDIR="${D}" altinstall

	# create a simple versionless 'python' symlink
	dosym "python${PYVER}" "${rawbindir}/python"
	dosym "python${PYVER}" "${rawbindir}/python3"

	rm -r "${libdir}/"{sqlite3,test/test_sqlite*} || die
	rm -r "${bindir}/idle${PYVER}" "${libdir}/"{idlelib,tkinter,test/test_tk*} || die

	rm "${libdir}/distutils/command/"wininst-*.exe || die

	rm -r "${ED}/discard" || die
}
