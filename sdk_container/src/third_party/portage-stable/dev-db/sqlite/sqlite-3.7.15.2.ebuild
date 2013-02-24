# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-db/sqlite/sqlite-3.7.15.2.ebuild,v 1.2 2013/01/18 22:48:48 floppym Exp $

EAPI="5"

inherit autotools eutils flag-o-matic multilib versionator

SRC_PV="$(printf "%u%02u%02u%02u" $(get_version_components))"
# DOC_PV="$(printf "%u%02u%02u00" $(get_version_components $(get_version_component_range 1-3)))"
DOC_PV="${SRC_PV}"

DESCRIPTION="A SQL Database Engine in a C Library"
HOMEPAGE="http://sqlite.org/"
SRC_URI="doc? ( http://sqlite.org/${PN}-doc-${DOC_PV}.zip )
	tcl? ( http://sqlite.org/${PN}-src-${SRC_PV}.zip )
	!tcl? (
		test? ( http://sqlite.org/${PN}-src-${SRC_PV}.zip )
		!test? ( http://sqlite.org/${PN}-autoconf-${SRC_PV}.tar.gz )
	)"

LICENSE="public-domain"
SLOT="3"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="debug doc +extensions +fts3 icu +readline secure-delete soundex static-libs tcl test +threadsafe unlock-notify"

RDEPEND="icu? ( dev-libs/icu:= )
	readline? ( sys-libs/readline )
	tcl? ( dev-lang/tcl:= )"
DEPEND="${RDEPEND}
	doc? ( app-arch/unzip )
	tcl? ( app-arch/unzip )
	test? (
		app-arch/unzip
		dev-lang/tcl
	)"

amalgamation() {
	use !tcl && use !test
}

pkg_setup() {
	if amalgamation; then
		S="${WORKDIR}/${PN}-autoconf-${SRC_PV}"
	else
		S="${WORKDIR}/${PN}-src-${SRC_PV}"
	fi
}

src_prepare() {
	# At least ppc-aix, x86-interix and *-solaris need newer libtool.
	use prefix && eautoreconf

	epunt_cxx
}

src_configure() {
	# `configure` from amalgamation tarball does not add -DSQLITE_DEBUG or -DNDEBUG flag.
	if amalgamation; then
		if use debug; then
			append-cppflags -DSQLITE_DEBUG
		else
			append-cppflags -DNDEBUG
		fi
	fi

	# Support column metadata (bug #266651)
	append-cppflags -DSQLITE_ENABLE_COLUMN_METADATA

	# Support R-trees (bug #257646)
	append-cppflags -DSQLITE_ENABLE_RTREE

	if use icu; then
		append-cppflags -DSQLITE_ENABLE_ICU
		if amalgamation; then
			sed -e "s/LIBS = @LIBS@/& -licui18n -licuuc/" -i Makefile.in || die "sed failed"
		else
			sed -e "s/TLIBS = @LIBS@/& -licui18n -licuuc/" -i Makefile.in || die "sed failed"
		fi
	fi

	# Support FTS3 (bug #207701)
	if use fts3; then
		append-cppflags -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS
	fi

	# Enable secure_delete pragma.
	if use secure-delete; then
		append-cppflags -DSQLITE_SECURE_DELETE -DSQLITE_CHECK_PAGES -DSQLITE_CORE
	fi

	# Support soundex (bug #143794).
	if use soundex; then
		append-cppflags -DSQLITE_SOUNDEX
	fi

	# Enable unlock notification.
	if use unlock-notify; then
		append-cppflags -DSQLITE_ENABLE_UNLOCK_NOTIFY
	fi

	local extensions_option
	if amalgamation; then
		extensions_option="dynamic-extensions"
	else
		extensions_option="load-extension"
	fi

	# Starting from 3.6.23, SQLite has locking strategies that are specific to
	# OSX. By default they are enabled, and use semantics that only make sense
	# on OSX. However, they require gethostuuid() function for that, which is
	# only available on OSX starting from 10.6 (Snow Leopard). For earlier
	# versions of OSX we have to disable all this nifty locking options, as
	# suggested by upstream.
	if [[ "${CHOST}" == *-darwin[56789] ]]; then
		append-cppflags -DSQLITE_ENABLE_LOCKING_STYLE="0"
	fi

	if [[ "${CHOST}" == *-mint* ]]; then
		append-cppflags -DSQLITE_OMIT_WAL
	fi

	# `configure` from amalgamation tarball does not support
	# --with-readline-inc and --(enable|disable)-tcl options.
	econf \
		$(use_enable extensions ${extensions_option}) \
		$(use_enable readline) \
		$(use_enable static-libs static) \
		$(use_enable threadsafe) \
		$(amalgamation || echo --with-readline-inc="-I${EPREFIX}/usr/include/readline") \
		$(amalgamation || use_enable debug) \
		$(amalgamation || echo --enable-tcl)
}

src_compile() {
	emake TCLLIBDIR="${EPREFIX}/usr/$(get_libdir)/${P}"
}

src_test() {
	if [[ "${EUID}" -eq 0 ]]; then
		ewarn "Skipping tests due to root permissions"
		return
	fi

	emake $(use debug && echo fulltest || echo test)
}

src_install() {
	emake DESTDIR="${D}" TCLLIBDIR="${EPREFIX}/usr/$(get_libdir)/${P}" install
	prune_libtool_files

	doman sqlite3.1

	if use doc; then
		find "${WORKDIR}/${PN}-doc-${DOC_PV}" -name ".[_~]*" -delete
		dohtml -A ico,odg,pdf,svg -r "${WORKDIR}/${PN}-doc-${DOC_PV}/"
	fi
}
