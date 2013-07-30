# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/jinja/jinja-2.6-r1.ebuild,v 1.4 2013/07/28 18:13:45 ago Exp $

EAPI=5

PYTHON_COMPAT=( python{2_5,2_6,2_7,3_1,3_2,3_3} pypy{1_9,2_0} )

inherit distutils-r1

MY_PN=Jinja2
MY_P=${MY_PN}-${PV}

DESCRIPTION="A small but fast and easy to use stand-alone template engine written in pure Python"
HOMEPAGE="http://jinja.pocoo.org/ http://pypi.python.org/pypi/Jinja2"
SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ~hppa ~ia64 ~mips ppc ~ppc64 ~s390 ~sh ~sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris"
IUSE="doc examples"

RDEPEND="dev-python/markupsafe[${PYTHON_USEDEP}]
	dev-python/setuptools[${PYTHON_USEDEP}]"
DEPEND="${RDEPEND}
	doc? ( >=dev-python/sphinx-0.6 )"

# XXX: handle Babel better?

S=${WORKDIR}/${MY_P}

wrap_opts() {
	local mydistutilsargs=()

	if [[ ${EPYTHON} == python* ]]; then
		mydistutilargs+=( --with-debugsupport )
	fi

	"${@}"
}

python_compile() {
	wrap_opts distutils-r1_python_compile
}

python_compile_all() {
	if use doc; then
		cd docs || die

		if [[ ${EPYTHON} == python3* ]]; then
			# https://github.com/mitsuhiko/jinja2/issues/115
			2to3 -n -w --no-diffs jinjaext.py || die
		fi

		emake html
	fi
}

python_test() {
	esetup.py test
}

python_install_all() {
	use doc && local HTML_DOCS=( docs/_build/html/. )

	distutils-r1_python_install_all

	if use examples; then
		insinto /usr/share/doc/${PF}
		doins -r examples
	fi

	insinto /usr/share/vim/vimfiles/syntax
	doins ext/Vim/*
}

pkg_postinst() {
	if ! has_version dev-python/Babel; then
		elog "For i18n support, please emerge dev-python/Babel."
	fi
}
