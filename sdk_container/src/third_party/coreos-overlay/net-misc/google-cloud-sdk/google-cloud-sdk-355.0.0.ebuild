# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python3_6 )

inherit bash-completion-r1 python-single-r1

DESCRIPTION="Command line tool for interacting with Google Compute Engine"
HOMEPAGE="https://cloud.google.com/sdk"
SRC_URI="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${P}-linux-x86_64.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

S="${WORKDIR}/${PN}"

DEPEND="${PYTHON_DEPS}"
RDEPEND="${DEPEND}
	dev-python/crcmod[${PYTHON_USEDEP}]"

src_prepare() {
	# Drop unused python2 code
	rm -r lib/third_party/httplib2/python2 || die
	rm -r lib/third_party/gcloud_crcmod/python2 || die
	rm -r lib/third_party/concurrent/{python2,futures} || die
	rm -r platform/gsutil/third_party/httplib2/python2 || die
	rm -r platform/gsutil/third_party/crcmod/python2 || die
	rm -r platform/bq/third_party/httplib2/python2 || die
	# Use the compiled crcmod from the system
	rm -r platform/gsutil/third_party/{crcmod,crcmod_osx} || die
	rm -r lib/third_party/gcloud_crcmod/python3/{_crcfunpy,crcmod,predefined}.py || die
	# Drop unused stuff
	rm -r platform/bq || die
	# Python optimize complains about syntax errors in these
	# files, so I suppose that they are unused at runtime.
	rm -r platform/gsutil/gslib/vendored/boto/{docs,tests/{fps,db}} || die
	rm -r platform/ext-runtime/nodejs/test
	rm -f platform/gsutil/third_party/apitools/ez_setup.py
	rm -r lib/third_party/yaml
	rm -r lib/googlecloudsdk/third_party/appengine/api
	rm -r lib/third_party/fancy_urllib

	default
}

src_install() {
	insinto "/usr/lib/${PN}"
	doins -r lib platform "${FILESDIR}/properties"
	insinto "/usr/lib/${PN}/bin"
	doins -r bin/bootstrapping

	python_optimize "${D}/usr/lib/${PN}"

	dobin "${FILESDIR}/"{gcloud,gsutil}
	dodoc LICENSE README RELEASE_NOTES

	newbashcomp completion.bash.inc gcloud
	bashcomp_alias gcloud gsutil
}
