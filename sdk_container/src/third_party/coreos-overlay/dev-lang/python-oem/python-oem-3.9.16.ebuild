# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"
WANT_LIBTOOL="none"

inherit autotools check-reqs flag-o-matic multiprocessing
inherit prefix python-utils-r1 toolchain-funcs verify-sig

MY_PV=${PV/_rc/rc}
MY_P="Python-${MY_PV%_p*}"
PYVER=$(ver_cut 1-2)
PATCHSET="python-gentoo-patches-${MY_PV}"

DESCRIPTION="An interpreted, interactive, object-oriented programming language"
HOMEPAGE="
	https://www.python.org/
	https://github.com/python/cpython/
"
SRC_URI="
	https://www.python.org/ftp/python/${PV%%_*}/${MY_P}.tar.xz
	https://dev.gentoo.org/~mgorny/dist/python/${PATCHSET}.tar.xz
	verify-sig? (
		https://www.python.org/ftp/python/${PV%%_*}/${MY_P}.tar.xz.asc
	)
"
S="${WORKDIR}/${MY_P}"

LICENSE="PSF-2"
SLOT="${PYVER}"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="hardened"

# Do not add a dependency on dev-lang/python to this ebuild.
# If you need to apply a patch which requires python for bootstrapping, please
# run the bootstrap code on your dev box and include the results in the
# patchset. See bug 447752.

DEPEND="
	app-arch/bzip2:=
	app-arch/xz-utils:=
	dev-lang/python-exec[python_targets_python3_9(-)]
	sys-apps/util-linux:=
	>=sys-libs/zlib-1.1.3:=
	virtual/libcrypt:=
	virtual/libintl
"
# autoconf-archive needed to eautoreconf
BDEPEND="
	sys-devel/autoconf-archive
	app-alternatives/awk
	virtual/pkgconfig
	verify-sig? ( sec-keys/openpgp-keys-python )
"

VERIFY_SIG_OPENPGP_KEY_PATH=${BROOT}/usr/share/openpgp-keys/python.org.asc

# large file tests involve a 2.5G file being copied (duplicated)
CHECKREQS_DISK_BUILD=5500M

QA_PKGCONFIG_VERSION=${PYVER}

src_unpack() {
	if use verify-sig; then
		verify-sig_verify_detached "${DISTDIR}"/${MY_P}.tar.xz{,.asc}
	fi
	default
}

src_prepare() {
	local PATCHES=(
		"${WORKDIR}/${PATCHSET}"
	)

	default

	# https://bugs.gentoo.org/850151
	sed -i -e "s:@@GENTOO_LIBDIR@@:$(get_libdir):g" setup.py || die

	# force the correct number of jobs
	# https://bugs.gentoo.org/737660
	local jobs=$(makeopts_jobs)
	sed -i -e "s:-j0:-j${jobs}:" Makefile.pre.in || die
	sed -i -e "/self\.parallel/s:True:${jobs}:" setup.py || die

	eautoreconf
}

src_configure() {
	# disable automagic bluetooth headers detection
	export ac_cv_header_bluetooth_bluetooth_h=no
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

	append-flags -fwrapv
	filter-flags -malign-double

	# https://bugs.gentoo.org/700012
	if is-flagq -flto || is-flagq '-flto=*'; then
		append-cflags $(test-flags-CC -ffat-lto-objects)
	fi

	if tc-is-cross-compiler; then
		# Force some tests that try to poke fs paths.
		export ac_cv_file__dev_ptc=no
		export ac_cv_file__dev_ptmx=yes
	fi

	# Export CXX so it ends up in /usr/lib/python3.X/config/Makefile.
	# PKG_CONFIG needed for cross.
	tc-export CXX PKG_CONFIG

	local dbmliborder=

	local myeconfargs=(
		# glibc-2.30 removes it; since we can't cleanly force-rebuild
		# Python on glibc upgrade, remove it proactively to give
		# a chance for users rebuilding python before glibc
		ac_cv_header_stropts_h=no

		--prefix=/usr/share/oem/python
		--with-platlibdir=$(get_libdir)
		--disable-shared
		--enable-ipv6
		--infodir='/discard/info'
		--mandir='/discard/man'
		--includedir='/discard/include'
		--with-computed-gotos
		--with-dbmliborder="${dbmliborder}"
		--with-libc=
		--enable-loadable-sqlite-extensions
		--without-ensurepip
		--without-system-expat
		--without-system-ffi
		--without-lto
		--disable-optimizations
	)

	# disable implicit optimization/debugging flags
	local -x OPT=

	if tc-is-cross-compiler ; then
		# Hack to workaround get_libdir not being able to handle CBUILD, bug #794181
		local cbuild_libdir=$(unset PKG_CONFIG_PATH ; $(tc-getBUILD_PKG_CONFIG) --keep-system-libs --libs-only-L libffi)

		# pass system CFLAGS & LDFLAGS as _NODIST, otherwise they'll get
		# propagated to sysconfig for built extensions
		local -x CFLAGS_NODIST=${CFLAGS_FOR_BUILD}
		local -x LDFLAGS_NODIST=${LDFLAGS_FOR_BUILD}
		local -x CFLAGS= LDFLAGS=

		# We need to build our own Python on CBUILD first, and feed it in.
		# bug #847910 and bug #864911.
		local myeconfargs_cbuild=(
			"${myeconfargs[@]}"

			--libdir="${cbuild_libdir:2}"

			# As minimal as possible for the mini CBUILD Python
			# we build just for cross.
			--without-lto
			--disable-optimizations
		)

		# Point the imminent CHOST build to the Python we just
		# built for CBUILD.
		export PATH="${WORKDIR}/${P}-${CBUILD}:${PATH}"

		mkdir "${WORKDIR}"/${P}-${CBUILD} || die
		pushd "${WORKDIR}"/${P}-${CBUILD} &> /dev/null || die
		# We disable _ctypes and _crypt for CBUILD because Python's setup.py can't handle locating
		# libdir correctly for cross.
		PYTHON_DISABLE_MODULES="${PYTHON_DISABLE_MODULES} _ctypes _crypt" \
			ECONF_SOURCE="${S}" econf_build "${myeconfargs_cbuild[@]}"

		# Avoid as many dependencies as possible for the cross build.
		cat >> Makefile <<-EOF || die
			MODULE_NIS=disabled
			MODULE__DBM=disabled
			MODULE__GDBM=disabled
			MODULE__DBM=disabled
			MODULE__SQLITE3=disabled
			MODULE__HASHLIB=disabled
			MODULE__SSL=disabled
			MODULE__CURSES=disabled
			MODULE__CURSES_PANEL=disabled
			MODULE_READLINE=disabled
			MODULE__TKINTER=disabled
			MODULE_PYEXPAT=disabled
			MODULE_ZLIB=disabled
		EOF

		# Unfortunately, we do have to build this immediately, and
		# not in src_compile, because CHOST configure for Python
		# will check the existence of the Python it was pointed to
		# immediately.
		PYTHON_DISABLE_MODULES="${PYTHON_DISABLE_MODULES} _ctypes _crypt" emake
		popd &> /dev/null || die
	fi

	# pass system CFLAGS & LDFLAGS as _NODIST, otherwise they'll get
	# propagated to sysconfig for built extensions
	local -x CFLAGS_NODIST=${CFLAGS}
	local -x LDFLAGS_NODIST=${LDFLAGS}
	local -x CFLAGS= LDFLAGS=

	hprefixify setup.py
	econf "${myeconfargs[@]}"

	if grep -q "#define POSIX_SEMAPHORES_NOT_ENABLED 1" pyconfig.h; then
		eerror "configure has detected that the sem_open function is broken."
		eerror "Please ensure that /dev/shm is mounted as a tmpfs with mode 1777."
		die "Broken sem_open function (bug 496328)"
	fi

	# install epython.py as part of stdlib
	echo "EPYTHON='python${PYVER}'" > Lib/epython.py || die
}

src_compile() {
	# Ensure sed works as expected
	# https://bugs.gentoo.org/594768
	local -x LC_ALL=C
	# Prevent using distutils bundled by setuptools.
	# https://bugs.gentoo.org/823728
	export SETUPTOOLS_USE_DISTUTILS=stdlib

	# Save PYTHONDONTWRITEBYTECODE so that 'has_version' doesn't
	# end up writing bytecode & violating sandbox.
	# bug #831897
	local -x _PYTHONDONTWRITEBYTECODE=${PYTHONDONTWRITEBYTECODE}

	# also need to clear the flags explicitly here or they end up
	# in _sysconfigdata*
	emake CPPFLAGS= CFLAGS= LDFLAGS=

	# Restore saved value from above.
	local -x PYTHONDONTWRITEBYTECODE=${_PYTHONDONTWRITEBYTECODE}
}

src_install() {
	local prefix=/usr/share/oem/python
	local eprefix="${ED}${prefix}"
	local elibdir="${eprefix}/$(get_libdir)"
	local epythonplatlibdir="${elibdir}/python${PYVER}"
	local bindir="${prefix}/bin"
	local ebindir="${eprefix}/bin"

	emake DESTDIR="${D}" altinstall

	# Remove static library
	rm "${elibdir}"/libpython*.a || die

	rm -r "${epythonplatlibdir}/"{sqlite3,test/test_sqlite*} || die
	rm -r "${ebindir}/idle${PYVER}" "${epythonplatlibdir}/"{idlelib,tkinter,test/test_tk*} || die

	# create a simple versionless 'python' symlink
	dosym "python${PYVER}" "${bindir}/python"
	dosym "python${PYVER}" "${bindir}/python3"

	rm -r "${ED}/discard" || die
}
