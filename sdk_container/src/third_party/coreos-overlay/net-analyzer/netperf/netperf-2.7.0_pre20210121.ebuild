# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools flag-o-matic

DESCRIPTION="Network performance benchmark"
HOMEPAGE="https://github.com/HewlettPackard/netperf"
EGIT_COMMIT="3bc455b23f901dae377ca0a558e1e32aa56b31c4"
SRC_URI="https://github.com/HewlettPackard/${PN}/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"


LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 arm64 ~hppa ~ia64 ppc ppc64 ~riscv sparc x86"
IUSE="demo sctp"

RDEPEND="
	acct-group/netperf
	acct-user/netperf
"
BDEPEND="
	${RDEPEND}
	sys-devel/gnuconfig
"

PATCHES=(
	"${FILESDIR}"/${PN}-fix-scripts.patch
	"${FILESDIR}"/${PN}-2.7.0-includes.patch
	"${FILESDIR}"/${PN}-2.7.0-fcommon.patch
)

S="${WORKDIR}/${PN}-${EGIT_COMMIT}"

src_prepare() {
	# Fixing paths in scripts
	sed -i \
		-e 's:^\(NETHOME=\).*:\1"/usr/bin":' \
		doc/examples/sctp_stream_script \
		doc/examples/tcp_range_script \
		doc/examples/tcp_rr_script \
		doc/examples/tcp_stream_script \
		doc/examples/udp_rr_script \
		doc/examples/udp_stream_script \
		|| die

	default
	# from autogen.sh
	eaclocal -I src/missing/m4
	eautomake
	eautoconf
	eautoheader
}

src_configure() {
	# netlib.c:2292:5: warning: implicit declaration of function ‘sched_setaffinity’
	# nettest_omni.c:2943:5: warning: implicit declaration of function ‘splice’
	# TODO: drop once https://github.com/HewlettPackard/netperf/pull/73 merged
	append-cppflags -D_GNU_SOURCE

	econf \
		$(use_enable demo) \
		$(use_enable sctp)
}

src_install() {
	default

	# Move netserver into sbin as we had it before 2.4 was released with its
	# autoconf goodness
	dodir /usr/sbin
	mv "${ED}"/usr/{bin,sbin}/netserver || die

	# init.d / conf.d
	newinitd "${FILESDIR}"/${PN}-2.7.0-init netperf
	newconfd "${FILESDIR}"/${PN}-2.2-conf netperf

	keepdir /var/log/${PN}
	fowners netperf:netperf /var/log/${PN}
	fperms 0755 /var/log/${PN}

	# documentation and example scripts
	dodoc AUTHORS ChangeLog NEWS README Release_Notes
	dodir /usr/share/doc/${PF}/examples
	# Scripts no longer get installed by einstall
	cp doc/examples/*_script "${ED}"/usr/share/doc/${PF}/examples || die
}
