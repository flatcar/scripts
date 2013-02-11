# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/Ice/Ice-3.4.2-r1.ebuild,v 1.3 2012/12/10 07:21:04 polynomial-c Exp $

EAPI="4"

PYTHON_DEPEND="python? 2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.*"
RUBY_OPTIONAL="yes"
USE_RUBY="ruby18"

inherit toolchain-funcs versionator python mono ruby-ng db-use

DESCRIPTION="ICE middleware C++ library and generator tools"
HOMEPAGE="http://www.zeroc.com/"
SRC_URI="http://www.zeroc.com/download/Ice/$(get_version_component_range 1-2)/${P}.tar.gz
	doc? ( http://www.zeroc.com/download/Ice/$(get_version_component_range 1-2)/${P}.pdf.gz )
	http://dev.gentoo.org/~ssuominen/${P}-gcc47.patch.bz2"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ia64 ~x86 ~x64-macos ~x86-linux"
IUSE="doc examples +ncurses mono python ruby test debug"

RDEPEND=">=dev-libs/expat-2.0.1
	>=app-arch/bzip2-1.0.5
	>=dev-libs/openssl-0.9.8o:0
	>=sys-libs/db-4.8.30[cxx]
	~dev-cpp/libmcpp-2.7.2
	ruby? ( $(ruby_implementation_depend ruby18) )
	mono? ( dev-lang/mono )
	!dev-python/IcePy
	!dev-ruby/IceRuby"
DEPEND="${RDEPEND}
	ncurses? ( sys-libs/ncurses sys-libs/readline )
	test? ( =dev-lang/python-2* )"

# Maintainer notes:
# - yes, we have to do the trickery with the move for the python functions
#   since the build and test frameworks deduce various settings from the path
#   and they can't be tricked by a symlink. And we also need
#   SUPPORT_PYTHON_ABIS=1 otherwise we can't get pyc/pyo anymore the sane way.
# TODO: php bindings
# TODO: java bindings

#overwrite ruby-ng.eclass default
S="${WORKDIR}/${P}"

pkg_setup() {
	if use python || use test; then
		python_pkg_setup
	fi
}

src_unpack() {
	# prevent ruby-ng.eclass from messing with src_unpack
	default
}

src_prepare() {
	epatch \
		"${FILESDIR}"/${PN}-3.4.1-db5.patch \
		"${FILESDIR}"/${PN}-3.4.2-gcc46.patch \
		"${WORKDIR}"/${PN}-3.4.2-gcc47.patch

	sed -i \
		-e 's|\(install_docdir[[:space:]]*\):=|\1?=|' \
		-e 's|\(install_configdir[[:space:]]*\):=|\1?=|' \
		cpp/config/Make.rules || die "sed failed"

	sed -i \
		-e 's|\(install_pythondir[[:space:]]*\):=|\1?=|' \
		-e 's|\(install_rubydir[[:space:]]*\):=|\1?=|' \
		-e 's|\(install_libdir[[:space:]]*\):=|\1?=|' \
		{py,rb}/config/Make.rules || die "sed failed"

	sed -i \
		-e 's|-O2 ||g' \
		cpp/config/Make.rules.Linux || die "sed failed"

	sed -i \
		-e 's|install-common||' \
		-e 's|demo||' \
		{cpp,cs,php,py,rb}/Makefile || die "sed failed"

	sed -i \
		-e 's|-f -root|-f -gacdir $(GAC_DIR) -root|' \
		cs/config/Make.rules.cs || die "sed failed"

	if ! use test ; then
		sed -i \
			-e 's|^\(SUBDIRS.*\)test|\1|' \
			{cpp,cs,php,py,rb}/Makefile || die "sed failed"
	fi
}

src_configure() {
	MAKE_RULES="prefix=\"${ED}/usr\"
		install_docdir=\"${ED}/usr/share/doc/${PF}\"
		install_configdir=\"${ED}/usr/share/Ice-${PV}/config\"
		embedded_runpath_prefix=\"${EPREFIX}/usr\"
		LP64=yes"

	use ncurses && OPTIONS="${MAKE_RULES} USE_READLINE=yes" || MAKE_RULES="${MAKE_RULES} USE_READLINE=no"
	use debug && OPTIONS"${MAKE_RULES} OPTIMIZE=no" || MAKE_RULES="${MAKE_RULES} OPTIMIZE=yes"

	MAKE_RULES="${MAKE_RULES} DB_FLAGS=-I$(db_includedir)"
	sed -i \
		-e "s|c++|$(tc-getCXX)|" \
		-e "s|\(CFLAGS[[:space:]]*=\)|\1 ${CFLAGS}|" \
		-e "s|\(CXXFLAGS[[:space:]]*=\)|\1 ${CXXFLAGS}|" \
		-e "s|\(LDFLAGS[[:space:]]*=\)|\1 ${LDFLAGS}|" \
		-e "s|\(DB_LIBS[[:space:]]*=\) \-ldb_cxx|\1 -ldb_cxx-$(db_findver sys-libs/db)|" \
		cpp/config/Make.rules{,.Linux} py/config/Make.rules || die "sed failed"

	if use python ; then
		python_copy_sources py
		mv py py.orig
	fi

	if use ruby ; then
		SITERUBY="$(ruby18 -r rbconfig -e 'print Config::CONFIG["sitedir"]')"
		MAKE_RULES_RB="install_rubydir=\"${ED}/${SITERUBY}\"
			install_libdir=\"${ED}/${SITERUBY}\""

		# make it use ruby18 only
		sed -i \
			-e 's|RUBY = ruby|\018|' \
			rb/config/Make.rules || die "sed failed"
	fi

	MAKE_RULES_CS="GACINSTALL=yes GAC_ROOT=\"${ED}/usr/$(get_libdir)\" GAC_DIR=${EPREFIX}/usr/$(get_libdir)"

}

src_compile() {
	if tc-is-cross-compiler ; then
		export CXX="${CHOST}-g++"
	fi

	emake -C cpp ${MAKE_RULES} || die "emake failed"

	if use doc ; then
		emake -C cpp/doc || die "building docs failed"
	fi

	if use python ; then
		building() {
			mv py-${PYTHON_ABI} py
			emake -C py ${MAKE_RULES} || die "emake py failed (for py-${PYTHON_ABI})"
			mv py py-${PYTHON_ABI}
		}
		python_execute_function building
	fi

	if use ruby ; then
		emake -C rb ${MAKE_RULES} ${MAKE_RULES_RB} || die "emake rb failed"
	fi

	if use mono ; then
		emake -C cs ${MAKE_RULES} ${MAKE_RULES_CS} || die "emake cs failed"
	fi
}

src_install() {
	dodoc CHANGES README

	insinto /usr/share/${P}
	doins -r slice

	emake -C cpp ${MAKE_RULES} install || die "emake install failed"

	docinto cpp
	dodoc CHANGES README

	if use examples ; then
		insinto /usr/share/doc/${PF}/examples-cpp
		doins cpp/config/*.cfg
		doins -r cpp/demo/*
	fi

	if use doc ; then
		dohtml -r cpp/doc/reference/*
		dodoc "${WORKDIR}/${P}.pdf"
	fi

	if use python ; then
		installation() {
			dodir $(python_get_sitedir)
			mv py-${PYTHON_ABI} py
			emake -C py ${MAKE_RULES} install_pythondir="\"${D}/$(python_get_sitedir)\"" install_libdir="\"${D}/$(python_get_sitedir)\"" install || die "emake py install failed (for py-${PYTHON_ABI})"
			mv py py-${PYTHON_ABI}
		}
		python_execute_function installation

		docinto py
		dodoc py.orig/CHANGES py.orig/README

		if use examples ; then
			insinto /usr/share/doc/${PF}/examples-py
			doins -r py.orig/demo/*
		fi

		cd "${ED}/$(python_get_sitedir -f)"
		PYTHON_MODULES=(*.py)
		PYTHON_MODULES+=(IceBox IceGrid IcePatch2 IceStorm)
		cd "${S}"
	fi

	if use ruby ; then
		dodir "${SITERUBY}"
		emake -C rb ${MAKE_RULES} ${MAKE_RULES_RB} install || die "emake rb install failed"

		docinto rb
		dodoc rb/CHANGES rb/README

		if use examples ; then
			insinto /usr/share/doc/${PF}/examples-rb
			doins -r rb/demo/*
		fi
	fi

	if use mono ; then
		emake -C cs ${MAKE_RULES} ${MAKE_RULES_CS} install || die "emake cs install failed"

		# TODO: anyone has an idea what those are for?
		rm "${ED}"/usr/bin/*.xml

		docinto cs
		dodoc cs/CHANGES cs/README

		if use examples ; then
			insinto /usr/share/doc/${PF}/examples-cs
			doins -r cs/demo/*
		fi
	fi
}

src_test() {
	emake -C cpp ${MAKE_RULES} test || die "emake test failed"

	if use python ; then
		testing() {
			mv py-${PYTHON_ABI} py
			emake -C py ${MAKE_RULES} test || die "emake py test failed (for py-${PYTHON_ABI})"
			mv py py-${PYTHON_ABI}
		}
		python_execute_function testing
	fi

	if use ruby ; then
		emake -C rb ${MAKE_RULES} ${MAKE_RULES_RB} test || die "emake rb test failed"
	fi

	if use mono ; then
#		ewarn "Tests for C# are currently disabled."
		emake -C cs ${MAKE_RULES} ${MAKE_RULES_CS} test || die "emake cs test failed"
	fi
}

pkg_postinst() {
	use python && python_mod_optimize "${PYTHON_MODULES[@]}"
}

pkg_postrm() {
	use python && python_mod_cleanup "${PYTHON_MODULES[@]}"
}
