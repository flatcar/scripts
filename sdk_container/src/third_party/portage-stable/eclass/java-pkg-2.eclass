# Eclass for Java packages
#
# Copyright (c) 2004-2005, Thomas Matthijs <axxo@gentoo.org>
# Copyright (c) 2004-2005, Gentoo Foundation
#
# Licensed under the GNU General Public License, v2
#
# $Header: /var/cvsroot/gentoo-x86/eclass/java-pkg-2.eclass,v 1.35 2010/02/01 09:38:44 caster Exp $

inherit java-utils-2

# -----------------------------------------------------------------------------
# @eclass-begin
# @eclass-summary Eclass for Java Packages
#
# This eclass should be inherited for pure Java packages, or by packages which
# need to use Java.
# -----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# @IUSE
#
# Use JAVA_PKG_IUSE instead of IUSE for doc, source and examples so that
# the eclass can automatically add the needed dependencies for the java-pkg_do*
# functions.
#
# ------------------------------------------------------------------------------
IUSE="${JAVA_PKG_IUSE}"

# ------------------------------------------------------------------------------
# @depend
#
# Java packages need java-config, and a fairly new release of Portage.
#
# JAVA_PKG_E_DEPEND is defined in java-utils.eclass.
# ------------------------------------------------------------------------------
DEPEND="${JAVA_PKG_E_DEPEND}"

# ------------------------------------------------------------------------------
# @rdepend
#
# Nothing special for RDEPEND... just the same as DEPEND.
# ------------------------------------------------------------------------------
RDEPEND="${DEPEND}"

# Commons packages follow the same rules so do it here
if [[ ${CATEGORY} = dev-java && ${PN} = commons-* ]]; then
	HOMEPAGE="http://commons.apache.org/${PN#commons-}/"
	SRC_URI="mirror://apache/${PN/-///}/source/${P}-src.tar.gz"
fi

case "${EAPI:-0}" in
	0|1) EXPORT_FUNCTIONS pkg_setup src_compile pkg_preinst ;;
	*) EXPORT_FUNCTIONS pkg_setup src_prepare src_compile pkg_preinst ;;
esac

# ------------------------------------------------------------------------------
# @eclass-pkg_setup
#
# pkg_setup initializes the Java environment
# ------------------------------------------------------------------------------
java-pkg-2_pkg_setup() {
	java-pkg_init
	java-pkg_ensure-test
}

# ------------------------------------------------------------------------------
# @eclass-src_prepare
#
# wrapper for java-utils-2_src_prepare
# ------------------------------------------------------------------------------
java-pkg-2_src_prepare() {
	java-utils-2_src_prepare
}

# ------------------------------------------------------------------------------
# @eclass-src_compile
#
# Default src_compile for java packages
# variables:
# EANT_BUILD_XML - controls the location of the build.xml (default: ./build.xml)
# EANT_FILTER_COMPILER - Calls java-pkg_filter-compiler with the value
# EANT_BUILD_TARGET - the ant target/targets to execute (default: jar)
# EANT_DOC_TARGET - the target to build extra docs under the doc use flag
#                   (default: javadoc; declare empty to disable completely)
# EANT_GENTOO_CLASSPATH - @see eant documention in java-utils-2.eclass
# EANT_EXTRA_ARGS - extra arguments to pass to eant
# EANT_ANT_TASKS - modifies the ANT_TASKS variable in the eant environment
# param: Parameters are passed to ant verbatim
# ------------------------------------------------------------------------------
java-pkg-2_src_compile() {
	if [[ -e "${EANT_BUILD_XML:=build.xml}" ]]; then
		[[ "${EANT_FILTER_COMPILER}" ]] && \
			java-pkg_filter-compiler ${EANT_FILTER_COMPILER}
		local antflags="${EANT_BUILD_TARGET:=jar}"
		if hasq doc ${IUSE} && [[ -n "${EANT_DOC_TARGET=javadoc}" ]]; then
			antflags="${antflags} $(use_doc ${EANT_DOC_TARGET})"
		fi
		local tasks
		[[ ${EANT_ANT_TASKS} ]] && tasks="${ANT_TASKS} ${EANT_ANT_TASKS}"
		ANT_TASKS="${tasks:-${ANT_TASKS}}" \
			eant ${antflags} -f "${EANT_BUILD_XML}" ${EANT_EXTRA_ARGS} "${@}"
	else
		echo "${FUNCNAME}: ${EANT_BUILD_XML} not found so nothing to do."
	fi
}

java-pkg-2_supports-test() {
	python << EOF
from xml.dom.minidom import parse
import sys
dom = parse("${1}")
for elem in dom.getElementsByTagName('target'):
	if elem.getAttribute('name') == 'test':
			sys.exit(0)
sys.exit(1)
EOF
	return $?
}

java-pkg-2_src_test() {
	[[ -e "${EANT_BUILD_XML:=build.xml}" ]] || return

	if [[ ${EANT_TEST_TARGET} ]] || java-pkg-2_supports-test ${EANT_BUILD_XML}; then
		local opts task

		if [[ ${EANT_TEST_JUNIT_INTO} ]]; then
			java-pkg_jar-from --into "${EANT_TEST_JUNIT_INTO}" junit
		fi

		ANT_TASKS=${EANT_TEST_ANT_TASKS:-${ANT_TASKS:-${EANT_ANT_TASKS}}}

		if [[ ${DEPEND} = *dev-java/ant-junit* ]]; then

			if [[ ${ANT_TASKS} && "${ANT_TASKS}" != none ]]; then
				ANT_TASKS="${ANT_TASKS} ant-junit"
			else
				ANT_TASKS="ant-junit"
			fi

			task=true
		fi

		if [[ ${task} ]] || [[ ${DEPEND} = *dev-java/junit* ]]; then
			opts="-Djunit.jar=\"$(java-pkg_getjar junit junit.jar)\""
			if [[ ${EANT_TEST_GENTOO_CLASSPATH} ]]; then
				EANT_GENTOO_CLASSPATH="${EANT_TEST_GENTOO_CLASSPATH},junit"
			elif [[ ${EANT_GENTOO_CLASSPATH} ]]; then
				EANT_GENTOO_CLASSPATH+=',junit'
			else
				EANT_GENTOO_CLASSPATH=junit
			fi
		fi

		eant ${opts} -f "${EANT_BUILD_XML}" \
			${EANT_EXTRA_ARGS} ${EANT_TEST_EXTRA_ARGS} ${EANT_TEST_TARGET:-test}

	else
		echo "${FUNCNAME}: No test target in ${EANT_BUILD_XML}"
	fi
}

# ------------------------------------------------------------------------------
# @eclass-pkg_preinst
#
# wrapper for java-utils-2_pkg_preinst
# ------------------------------------------------------------------------------
java-pkg-2_pkg_preinst() {
	java-utils-2_pkg_preinst
}

# ------------------------------------------------------------------------------
# @eclass-end
# ------------------------------------------------------------------------------
