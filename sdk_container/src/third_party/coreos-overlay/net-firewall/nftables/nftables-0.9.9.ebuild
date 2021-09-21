# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_7 )

inherit autotools linux-info python-r1 systemd

DESCRIPTION="Linux kernel (3.13+) firewall, NAT and packet mangling tools"
HOMEPAGE="https://netfilter.org/projects/nftables/"

if [[ ${PV} =~ ^[9]{4,}$ ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://git.netfilter.org/${PN}"

	BDEPEND="
		sys-devel/bison
		sys-devel/flex
	"
else
	SRC_URI="https://netfilter.org/projects/nftables/files/${P}.tar.bz2"
	KEYWORDS="amd64 arm arm64 ~ia64 ppc ~ppc64 ~riscv sparc x86"
fi

LICENSE="GPL-2"
SLOT="0/1"
IUSE="debug doc +gmp json libedit +modern-kernel python +readline static-libs xtables"

RDEPEND="
	>=net-libs/libmnl-1.0.4:0=
	>=net-libs/libnftnl-1.2.0:0=
	gmp? ( dev-libs/gmp:0= )
	json? ( dev-libs/jansson:= )
	python? ( ${PYTHON_DEPS} )
	readline? ( sys-libs/readline:0= )
	xtables? ( >=net-firewall/iptables-1.6.1 )
"

DEPEND="${RDEPEND}"

BDEPEND+="
	doc? (
		app-text/asciidoc
		>=app-text/docbook2X-0.8.8-r4
	)
	virtual/pkgconfig
"

REQUIRED_USE="
	python? ( ${PYTHON_REQUIRED_USE} )
	libedit? ( !readline )
"

PATCHES=(
	"${FILESDIR}/${PN}-0.9.8-slibtool.patch"
)

python_make() {
	emake \
		-C py \
		abs_builddir="${S}" \
		DESTDIR="${D}" \
		PYTHON_BIN="${PYTHON}" \
		"${@}"
}

pkg_setup() {
	if kernel_is ge 3 13; then
		if use modern-kernel && kernel_is lt 3 18; then
			eerror "The modern-kernel USE flag requires kernel version 3.18 or newer to work properly."
		fi
		CONFIG_CHECK="~NF_TABLES"
		linux-info_pkg_setup
	else
		eerror "This package requires kernel version 3.13 or newer to work properly."
	fi
}

src_prepare() {
	default

	# fix installation path for doc stuff
	sed '/^pkgsysconfdir/s@${sysconfdir}.*$@${docdir}/skels@' \
		-i files/nftables/Makefile.am || die
	sed '/^pkgsysconfdir/s@${sysconfdir}.*$@${docdir}/skels/osf@' \
		-i files/osf/Makefile.am || die

	eautoreconf
}

src_configure() {
	local myeconfargs=(
		# We handle python separately
		--disable-python
		--sbindir="${EPREFIX}"/sbin
		--sysconfdir="${EPREFIX}"/usr/share 
		$(use_enable debug)
		$(use_enable doc man-doc)
		$(use_with !gmp mini_gmp)
		$(use_with json)
		$(use_with libedit cli editline)
		$(use_with readline cli readline)
		$(use_enable static-libs static)
		$(use_with xtables)
	)
	econf "${myeconfargs[@]}"
}

src_compile() {
	default

	if use python; then
		python_foreach_impl python_make
	fi
}

src_install() {
	default
	find "${ED}" -type f -name "*.la" -delete || die
}
