# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"
WANT_LIBTOOL="none"

inherit autotools check-reqs flag-o-matic multiprocessing pax-utils
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
IUSE="
	bluetooth build +ensurepip examples gdbm hardened libedit lto
	+ncurses pgo +readline +sqlite +ssl test tk valgrind +xml
"
RESTRICT="!test? ( test )"

# Do not add a dependency on dev-lang/python to this ebuild.
# If you need to apply a patch which requires python for bootstrapping, please
# run the bootstrap code on your dev box and include the results in the
# patchset. See bug 447752.

# Flatcar: Drop a dependency on dev-libs/expat, we will use the internal one.
# Flatcar: Drop a dependency on dev-libs/libffi, we will use the internal one.
# Flatcar: Drop a dependency on dev-python/gentoo-common, we will install our own EXTERNALLY-MANAGED file
RDEPEND="
	app-arch/bzip2:=
	app-arch/xz-utils:=
	dev-lang/python-exec[python_targets_python3_10(-)]
	dev-python/gentoo-common
	sys-apps/util-linux:=
	>=sys-libs/zlib-1.1.3:=
	virtual/libcrypt:=
	virtual/libintl
	ensurepip? ( dev-python/ensurepip-wheels )
	gdbm? ( sys-libs/gdbm:=[berkdb] )
	ncurses? ( >=sys-libs/ncurses-5.2:= )
	readline? (
		!libedit? ( >=sys-libs/readline-4.1:= )
		libedit? ( dev-libs/libedit:= )
	)
	sqlite? ( >=dev-db/sqlite-3.3.8:3= )
	ssl? ( >=dev-libs/openssl-1.1.1:= )
	tk? (
		>=dev-lang/tcl-8.0:=
		>=dev-lang/tk-8.0:=
		dev-tcltk/blt:=
		dev-tcltk/tix
	)
	!!<sys-apps/sandbox-2.21
"
# bluetooth requires headers from bluez
DEPEND="
	${RDEPEND}
	bluetooth? ( net-wireless/bluez )
	valgrind? ( dev-util/valgrind )
	test? ( app-arch/xz-utils[extra-filters(+)] )
"
# autoconf-archive needed to eautoreconf
BDEPEND="
	sys-devel/autoconf-archive
	app-alternatives/awk
	virtual/pkgconfig
	verify-sig? ( sec-keys/openpgp-keys-python )
"
RDEPEND+="
	!build? ( app-misc/mime-types )
"

# Flatcar: Unset RDEPEND, DEPEND already contains it. OEM packages are
# installed after production images are pruned of the previously
# installed package database.
unset RDEPEND

VERIFY_SIG_OPENPGP_KEY_PATH=${BROOT}/usr/share/openpgp-keys/python.org.asc

# large file tests involve a 2.5G file being copied (duplicated)
CHECKREQS_DISK_BUILD=5500M

QA_PKGCONFIG_VERSION=${PYVER}

pkg_pretend() {
	use test && check-reqs_pkg_pretend
}

pkg_setup() {
	use test && check-reqs_pkg_setup
}

src_unpack() {
	if use verify-sig; then
		verify-sig_verify_detached "${DISTDIR}"/${MY_P}.tar.xz{,.asc}
	fi
	default
}

src_prepare() {
	# Flatcar: We keep the internal expat copy.
	# Flatcar: We keep the internal libffi copy.
	# # Ensure that internal copies of expat and libffi are not used.
	# rm -r Modules/expat || die
	# rm -r Modules/_ctypes/libffi* || die

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
	if ! use bluetooth; then
		local -x ac_cv_header_bluetooth_bluetooth_h=no
	fi
	local disable
	use gdbm      || disable+=" gdbm"
	use ncurses   || disable+=" _curses _curses_panel"
	use readline  || disable+=" readline"
	use sqlite    || disable+=" _sqlite3"
	use ssl       || export PYTHON_DISABLE_SSL="1"
	use tk        || disable+=" _tkinter"
	use xml       || disable+=" _elementtree pyexpat" # _elementtree uses pyexpat.
	export PYTHON_DISABLE_MODULES="${disable}"

	if ! use xml; then
		ewarn "You have configured Python without XML support."
		ewarn "This is NOT a recommended configuration as you"
		ewarn "may face problems parsing any XML documents."
	fi

	if [[ -n "${PYTHON_DISABLE_MODULES}" ]]; then
		einfo "Disabled modules: ${PYTHON_DISABLE_MODULES}"
	fi

	append-flags -fwrapv
	filter-flags -malign-double

	# https://bugs.gentoo.org/700012
	if is-flagq -flto || is-flagq '-flto=*'; then
		append-cflags $(test-flags-CC -ffat-lto-objects)
	fi

	# Export CXX so it ends up in /usr/lib/python3.X/config/Makefile.
	# PKG_CONFIG needed for cross.
	tc-export CXX PKG_CONFIG

	local dbmliborder=
	if use gdbm; then
		dbmliborder+="${dbmliborder:+:}gdbm"
	fi

	if use pgo; then
		local profile_task_flags=(
			-m test
			"-j$(makeopts_jobs)"
			--pgo-extended
			-x test_gdb
			-u-network

			# All of these seem to occasionally hang for PGO inconsistently
			# They'll even hang here but be fine in src_test sometimes.
			# bug #828535 (and related: bug #788022)
			-x test_asyncio
			-x test_httpservers
			-x test_logging
			-x test_multiprocessing_fork
			-x test_socket
			-x test_xmlrpc
		)

		if has_version "app-arch/rpm" ; then
			# Avoid sandbox failure (attempts to write to /var/lib/rpm)
			profile_task_flags+=(
				-x test_distutils
			)
		fi
		local -x PROFILE_TASK="${profile_task_flags[*]}"
	fi

	local myeconfargs=(
		# glibc-2.30 removes it; since we can't cleanly force-rebuild
		# Python on glibc upgrade, remove it proactively to give
		# a chance for users rebuilding python before glibc
		ac_cv_header_stropts_h=no

		# Flatcar: Use oem-specific prefix.
		--prefix=/usr/share/oem/python
		# Flatcar: Make sure we put libs into a correct subdirectory.
		--with-platlibdir="$(get_libdir)"
		# Flatcar: No need for shared libs.
		# --enable-shared
		--disable-shared
		--without-static-libpython
		--enable-ipv6
		# Flatcar: Set includedir to discardable directory
		--includedir='/discard/include'
		# Flatcar: Set infodir and mandir to discardable directory
		# --infodir='/${prefix}/share/info'
		# --mandir='/${prefix}/share/man'
		--infodir='/discard/info'
		--mandir='/discard/man'
		--with-computed-gotos
		--with-dbmliborder="${dbmliborder}"
		--with-libc=
		# Flatcar: No need for loadable extensions.
		# --enable-loadable-sqlite-extensions
		--disable-loadable-sqlite-extensions
		--without-ensurepip
		# Flatcar: We use internal expat
		# --with-system-expat
		--without-system-expat
		# Flatcar: We use internal ffi
		# --with-system-ffi
		--without-system-ffi
		# Flatcar: It's for ensurepip, which we disable
		# --with-wheel-pkg-dir="${EPREFIX}"/usr/lib/python/ensurepip

		$(use_with lto)
		$(use_enable pgo optimizations)
		$(use_with readline readline "$(usex libedit editline readline)")
		$(use_with valgrind)
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

			# Avoid needing to load the right libpython.so.
			--disable-shared

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

	# Fix implicit declarations on cross and prefix builds. Bug #674070.
	if use ncurses; then
		append-cppflags -I"${ESYSROOT}"/usr/include/ncursesw
	fi

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

	if use pgo ; then
		# bug 660358
		local -x COLUMNS=80
		local -x PYTHONDONTWRITEBYTECODE=

		addpredict "/usr/lib/python${PYVER}/site-packages"
	fi

	# also need to clear the flags explicitly here or they end up
	# in _sysconfigdata*
	emake CPPFLAGS= CFLAGS= LDFLAGS=

	# Restore saved value from above.
	local -x PYTHONDONTWRITEBYTECODE=${_PYTHONDONTWRITEBYTECODE}

	# Work around bug 329499. See also bug 413751 and 457194.
	if has_version dev-libs/libffi[pax-kernel]; then
		pax-mark E python
	else
		pax-mark m python
	fi
}

src_test() {
	# Tests will not work when cross compiling.
	if tc-is-cross-compiler; then
		elog "Disabling tests due to crosscompiling."
		return
	fi

	local test_opts=(
		-u-network
		-j "$(makeopts_jobs)"

		# fails
		-x test_gdb
	)

	if use sparc ; then
		# bug #788022
		test_opts+=(
			-x test_multiprocessing_fork
			-x test_multiprocessing_forkserver
		)
	fi

	# workaround docutils breaking tests
	cat > Lib/docutils.py <<-EOF || die
		raise ImportError("Thou shalt not import!")
	EOF

	# bug 660358
	local -x COLUMNS=80
	local -x PYTHONDONTWRITEBYTECODE=
	# workaround https://bugs.gentoo.org/775416
	addwrite "/usr/lib/python${PYVER}/site-packages"

	nonfatal emake test EXTRATESTOPTS="${test_opts[*]}" \
		CPPFLAGS= CFLAGS= LDFLAGS= < /dev/tty
	local ret=${?}

	rm Lib/docutils.py || die

	[[ ${ret} -eq 0 ]] || die "emake test failed"
}

# Flatcar: Rewrite src_install to just run make altinstall, remove
# some installed files (refer to the original src_install to see which
# files to drop), adding symlinks and the EXTERNALLY-MANAGED file, and
# removing the /discard directory.
src_install() {
	local prefix=/usr/share/oem/python
	local eprefix="${ED}${prefix}"
        local libdir="${prefix}/$(get_libdir)"
	local elibdir="${eprefix}/$(get_libdir)"
	local pythonplatlibdir="${libdir}/python${PYVER}"
	local epythonplatlibdir="${elibdir}/python${PYVER}"
	local bindir="${prefix}/bin"
	local ebindir="${eprefix}/bin"

	emake DESTDIR="${D}" altinstall

	rm -r "${epythonplatlibdir}"/ensurepip || die
	rm -r "${epythonplatlibdir}/"{sqlite3,test/test_sqlite*} || die
	rm -r "${ebindir}/idle${PYVER}" || die
	rm -r "${epythonplatlibdir}/"{idlelib,tkinter,test/test_tk*} || die

	# create a simple versionless 'python' symlink
	dosym "python${PYVER}" "${bindir}/python"
	dosym "python${PYVER}" "${bindir}/python3"

	insinto "${pythonplatlibdir}"
	# https://peps.python.org/pep-0668/
	newins - EXTERNALLY-MANAGED <<-EOF
		[externally-managed]
		Error=
		 Please contact Flatcar maintainers if some python package
		 is necessary for this OEM image.
	EOF

	rm -r "${ED}/discard" || die
}
