#!/bin/bash

EAPI=5
source tests-common.sh

test_var() {
	local var=${1}
	local impl=${2}
	local expect=${3}

	tbegin "${var} for ${impl}"

	local ${var}
	python_export ${impl} ${var}
	[[ ${!var} == ${expect} ]] || eerror "(${impl}: ${var}: ${!var} != ${expect}"

	tend ${?}
}

test_is() {
	local func=${1}
	local EPYTHON=${2}
	local expect=${3}

	tbegin "${func} for ${EPYTHON} (expecting: ${3})"

	${func}
	[[ ${?} == ${expect} ]]

	tend ${?}
}

inherit python-utils-r1

test_var EPYTHON python2_7 python2.7
test_var PYTHON python2_7 /usr/bin/python2.7
test_var PYTHON_SITEDIR python2_7 /usr/lib/python2.7/site-packages
test_var PYTHON_INCLUDEDIR python2_7 /usr/include/python2.7
test_var PYTHON_LIBPATH python2_7 /usr/lib/libpython2.7$(get_libname)
test_var PYTHON_PKG_DEP python2_7 dev-lang/python:2.7
test_var PYTHON_SCRIPTDIR python2_7 /usr/lib/python-exec/python2.7

test_var EPYTHON python3_3 python3.3
test_var PYTHON python3_3 /usr/bin/python3.3
test_var PYTHON_SITEDIR python3_3 /usr/lib/python3.3/site-packages
test_var PYTHON_INCLUDEDIR python3_3 /usr/include/python3.3
test_var PYTHON_LIBPATH python3_3 /usr/lib/libpython3.3$(get_libname)
test_var PYTHON_PKG_DEP python3_3 dev-lang/python:3.3
test_var PYTHON_SCRIPTDIR python3_3 /usr/lib/python-exec/python3.3

test_var EPYTHON jython2_7 jython2.7
test_var PYTHON jython2_7 /usr/bin/jython2.7
test_var PYTHON_SITEDIR jython2_7 /usr/share/jython-2.7/Lib/site-packages
test_var PYTHON_PKG_DEP jython2_7 dev-java/jython:2.7
test_var PYTHON_SCRIPTDIR jython2_7 /usr/lib/python-exec/jython2.7

test_var EPYTHON pypy2_0 pypy-c2.0
test_var PYTHON pypy2_0 /usr/bin/pypy-c2.0
test_var PYTHON_SITEDIR pypy2_0 /usr/lib/pypy2.0/site-packages
test_var PYTHON_INCLUDEDIR pypy2_0 /usr/lib/pypy2.0/include
test_var PYTHON_PKG_DEP pypy2_0 virtual/pypy:2.0
test_var PYTHON_SCRIPTDIR pypy2_0 /usr/lib/python-exec/pypy-c2.0

test_is python_is_python3 python2.7 1
test_is python_is_python3 python3.2 0
test_is python_is_python3 jython2.7 1
test_is python_is_python3 pypy2.0 1

texit
