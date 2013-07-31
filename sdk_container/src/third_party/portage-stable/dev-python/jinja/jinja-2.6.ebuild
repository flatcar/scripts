# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/jinja/jinja-2.6.ebuild,v 1.14 2012/05/09 00:15:37 aballier Exp $

EAPI=4

SUPPORT_PYTHON_ABIS="1"
DISTUTILS_SRC_TEST="setup.py"

inherit distutils

MY_PN=Jinja2
MY_P=${MY_PN}-${PV}

DESCRIPTION="A small but fast and easy to use stand-alone template engine written in pure python."
HOMEPAGE="http://jinja.pocoo.org/ http://pypi.python.org/pypi/Jinja2"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris"
IUSE="doc examples i18n vim-syntax"

RDEPEND="dev-python/markupsafe
	dev-python/setuptools
	i18n? ( >=dev-python/Babel-0.9.3 )"
DEPEND="${RDEPEND}
	doc? ( >=dev-python/sphinx-0.6 )"

S=${WORKDIR}/${MY_P}

DOCS="CHANGES"
PYTHON_MODNAME="jinja2"

DISTUTILS_GLOBAL_OPTIONS=("*-cpython --with-debugsupport")

src_compile(){
	distutils_src_compile

	if use doc; then
		einfo "Generation of documentation"
		pushd docs > /dev/null
		if [[ "$(python_get_version -f -l --major)" == "3" ]]; then
			# https://github.com/mitsuhiko/jinja2/issues/115
			2to3-$(PYTHON -f --ABI) -nw --no-diffs jinjaext.py || die
		fi
		PYTHONPATH="$(ls -d ../build-$(PYTHON -f --ABI)/lib*)" emake html
		popd > /dev/null
	fi
}

src_install(){
	distutils_src_install
	python_clean_installation_image

	delete_tests() {
		rm -fr "${ED}$(python_get_sitedir)/jinja2/testsuite"
	}
	python_execute_function -q delete_tests

	if use doc; then
		dohtml -r docs/_build/html/*
	fi

	if use examples; then
		insinto /usr/share/doc/${PF}
		doins -r examples
	fi

	if use vim-syntax; then
		insinto /usr/share/vim/vimfiles/syntax
		doins ext/Vim/*
	fi
}
