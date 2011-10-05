# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libxslt/libxslt-1.1.26-r1.ebuild,v 1.7 2011/03/18 17:30:53 armin76 Exp $

EAPI="3"
PYTHON_DEPEND="python? 2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.* *-jython"

inherit autotools eutils python toolchain-funcs

DESCRIPTION="XSLT libraries and tools"
HOMEPAGE="http://www.xmlsoft.org/"
SRC_URI="ftp://xmlsoft.org/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="crypt debug python"

DEPEND=">=dev-libs/libxml2-2.6.27:2
	crypt?  ( >=dev-libs/libgcrypt-1.1.42 )"
RDEPEND="${DEPEND}"

pkg_setup() {
	if use python; then
		python_pkg_setup
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/libxslt.m4-${P}.patch \
		"${FILESDIR}"/${PN}-1.1.23-parallel-install.patch \
		"${FILESDIR}"/${P}-undefined.patch \
		"${FILESDIR}"/${P}-disable_static_modules.patch

	# Python bindings are built/tested/installed manually.
	sed -e "s/@PYTHON_SUBDIR@//" -i Makefile.am || die "sed failed"

	# Fix generate-id() to not expose object addresses, bug #358615
	epatch "${FILESDIR}/${P}-id-generation.patch"

	eautoreconf
	epunt_cxx
}

src_configure() {
	# libgcrypt is missing pkg-config file, so fixing cross-compile
	# here. see bug 267503.
	if tc-is-cross-compiler; then
		export LIBGCRYPT_CONFIG="${SYSROOT}/usr/bin/libgcrypt-config"
	fi

	econf \
		--disable-dependency-tracking \
		--with-html-dir=/usr/share/doc/${PF} \
		--with-html-subdir=html \
		$(use_with crypt crypto) \
		$(use_with python) \
		$(use_with debug) \
		$(use_with debug mem-debug)
}

src_compile() {
	default

	if use python; then
		python_copy_sources python
		building() {
			emake PYTHON_INCLUDES="$(python_get_includedir)" \
				PYTHON_SITE_PACKAGES="$(python_get_sitedir)" \
				PYTHON_VERSION="$(python_get_version)"
		}
		python_execute_function -s --source-dir python building
	fi
}

src_test() {
	default

	if use python; then
		testing() {
			emake test
		}
		python_execute_function -s --source-dir python testing
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die

	if use python; then
		installation() {
			emake DESTDIR="${D}" \
				PYTHON_SITE_PACKAGES="$(python_get_sitedir)" \
				install
		}
		python_execute_function -s --source-dir python installation

		python_clean_installation_image
	fi

	mv -vf "${ED}"/usr/share/doc/${PN}-python-${PV} \
		"${ED}"/usr/share/doc/${PF}/python
	dodoc AUTHORS ChangeLog FEATURES NEWS README TODO || die
}

pkg_postinst() {
	if use python; then
		python_mod_optimize libxslt.py
	fi
}

pkg_postrm() {
	if use python; then
		python_mod_cleanup libxslt.py
	fi
}
