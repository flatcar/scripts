# Copyright 2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License, v2 or later
# $Header: /var/cvsroot/gentoo-x86/eclass/twisted.eclass,v 1.7 2009/10/30 13:14:17 arfrever Exp $
#
# Author: Marien Zwart <marienz@gentoo.org>
#
# eclass to aid installing and testing twisted packages.
#
# you should set MY_PACKAGE to something like 'Names' before inheriting.
# you may set MY_PV to the right version (defaults to PV).
#
# twisted_src_test relies on the package installing twisted.names to
# have a ${PN} of twisted-names.

inherit distutils eutils versionator

MY_PV="${MY_PV:-${PV}}"
MY_VERSION="$(get_version_component_range 1-2 ${MY_PV})"
MY_P="Twisted${MY_PACKAGE}-${MY_PV}"

HOMEPAGE="http://www.twistedmatrix.com/"
SRC_URI="http://tmrc.mit.edu/mirror/twisted/${MY_PACKAGE}/${MY_VERSION}/${MY_P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
IUSE=""

S="${WORKDIR}/${MY_P}"

twisted_src_test() {
	if [[ -n "${SUPPORT_PYTHON_ABIS}" ]]; then
		testing() {
			# This is a hack to make tests work without installing to the live
			# filesystem. We copy the twisted site-packages to a temporary
			# dir, install there, and run from there.
			local spath="$(python_get_sitedir)"
			mkdir -p "${T}/${spath}"
			cp -R "${ROOT}${spath}/twisted" "${T}/${spath}" || die "Copying of files failed with Python ${PYTHON_ABI}"

			# We have to get rid of the existing version of this package
			# instead of just installing on top of it, since if the existing
			# package has tests in files the version we are installing does
			# not have we end up running e.g. twisted-names-0.3.0 tests when
			# downgrading to twisted-names-0.1.0-r1.
			rm -fr "${T}/${spath}/${PN/-//}"

			"$(PYTHON)" setup.py build -b "build-${PYTHON_ABI}" install --root="${T}" --no-compile --force || die "Installation for tests failed with Python ${PYTHON_ABI}"
			cd "${T}/${spath}" || die
			PATH="${T}/usr/bin:${PATH}" PYTHONPATH="${T}/${spath}" trial ${PN/-/.} || die "trial failed with Python ${PYTHON_ABI}"
			cd "${S}"
			rm -fr "${T}/${spath}"
		}
		python_execute_function testing
	else
		# This is a hack to make tests work without installing to the live
		# filesystem. We copy the twisted site-packages to a temporary
		# dir, install there, and run from there.
		local spath="$(python_get_sitedir)"
		mkdir -p "${T}/${spath}"
		cp -R "${ROOT}${spath}/twisted" "${T}/${spath}" || die

		# We have to get rid of the existing version of this package
		# instead of just installing on top of it, since if the existing
		# package has tests in files the version we are installing does
		# not have we end up running fex twisted-names-0.3.0 tests when
		# downgrading to twisted-names-0.1.0-r1.
		rm -rf "${T}/${spath}/${PN/-//}"

		"${python}" setup.py install --root="${T}" --no-compile --force || die
		cd "${T}/${spath}" || die
		PATH="${T}/usr/bin:${PATH}" PYTHONPATH="${T}/${spath}" \
			trial ${PN/-/.} || die "trial failed"
		cd "${S}"
		rm -rf "${T}/${spath}"
	fi
}

twisted_src_install() {
	distutils_src_install

	if [[ -d doc/man ]]; then
		doman doc/man/*
	fi

	if [[ -d doc ]]; then
		insinto /usr/share/doc/${PF}
		doins -r $(find doc -mindepth 1 -maxdepth 1 -not -name man)
	fi
}

update_plugin_cache() {
	einfo "Updating twisted plugin cache..."
	# we have to remove the cache or removed plugins won't be removed
	# from the cache (http://twistedmatrix.com/bugs/issue926)
	rm "${ROOT}$(python_get_sitedir)/twisted/plugins/dropin.cache"
	# notice we have to use getPlugIns here for <=twisted-2.0.1 compatibility
	python -c "from twisted.plugin import IPlugin, getPlugIns;list(getPlugIns(IPlugin))"
}

twisted_pkg_postrm() {
	distutils_pkg_postrm
	if [[ -n "${SUPPORT_PYTHON_ABIS}" ]]; then
		python_execute_function update_plugin_cache
	else
		update_plugin_cache
	fi
}

twisted_pkg_postinst() {
	distutils_pkg_postinst
	if [[ -n "${SUPPORT_PYTHON_ABIS}" ]]; then
		python_execute_function update_plugin_cache
	else
		update_plugin_cache
	fi
}

EXPORT_FUNCTIONS src_test src_install pkg_postrm pkg_postinst
