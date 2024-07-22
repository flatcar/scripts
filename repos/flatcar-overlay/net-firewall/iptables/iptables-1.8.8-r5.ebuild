# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd toolchain-funcs autotools flag-o-matic usr-ldscript

DESCRIPTION="Linux kernel (2.4+) firewall, NAT and packet mangling tools"
HOMEPAGE="https://www.netfilter.org/projects/iptables/"
SRC_URI="https://www.netfilter.org/projects/iptables/files/${P}.tar.bz2"

LICENSE="GPL-2"
# Subslot reflects PV when libxtables and/or libip*tc was changed
# the last time.
SLOT="0/1.8.3"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="conntrack netlink nftables pcap static-libs"

COMMON_DEPEND="
	conntrack? ( >=net-libs/libnetfilter_conntrack-1.0.6 )
	netlink? ( net-libs/libnfnetlink )
	nftables? (
		>=net-libs/libmnl-1.0:=
		>=net-libs/libnftnl-1.1.6:=
	)
	pcap? ( net-libs/libpcap )
"
DEPEND="
	${COMMON_DEPEND}
	virtual/os-headers
	>=sys-kernel/linux-headers-4.4:0
"
BDEPEND="
	virtual/pkgconfig
	nftables? (
		sys-devel/flex
		app-alternatives/yacc
	)
"
# Flatcar: Drop net-firewall/arptables as we don't ship arptables.
RDEPEND="
	${COMMON_DEPEND}
	nftables? ( net-misc/ethertypes )
	!<net-firewall/ebtables-2.0.11-r1
"
# Flatcar: Do not ship eselect-iptables.

PATCHES=(
	"${FILESDIR}/iptables-1.8.4-no-symlinks.patch"
	"${FILESDIR}/iptables-1.8.2-link.patch"

	"${FILESDIR}/${P}-format-security.patch"
	"${FILESDIR}/${P}-uint-musl.patch"
	"${FILESDIR}/${P}-musl-headers.patch"
	"${FILESDIR}/${P}-out-of-tree-build.patch"
)

src_prepare() {
	# Use the saner headers from the kernel
	rm include/linux/{kernel,types}.h || die

	default
	eautoreconf
}

src_configure() {
	# Some libs use $(AR) rather than libtool to build, bug #444282
	tc-export AR

	# Hack around struct mismatches between userland & kernel for some ABIs
	# bug #472388
	use amd64 && [[ ${ABI} == "x32" ]] && append-flags -fpack-struct

	sed -i \
		-e "/nfnetlink=[01]/s:=[01]:=$(usex netlink 1 0):" \
		-e "/nfconntrack=[01]/s:=[01]:=$(usex conntrack 1 0):" \
		configure || die

	local myeconfargs=(
		--sbindir="${EPREFIX}/sbin"
		--libexecdir="${EPREFIX}/$(get_libdir)"
		--enable-devel
		--enable-ipv6
		--enable-shared
		$(use_enable nftables)
		$(use_enable pcap bpf-compiler)
		$(use_enable pcap nfsynproxy)
		$(use_enable static-libs static)
	)

	econf "${myeconfargs[@]}"
}

src_compile() {
	emake V=1
}

src_install() {
	default

	# Managed by eselect-iptables
	# https://bugs.gentoo.org/881295
	rm "${ED}/usr/bin/iptables-xml" || die

	dodoc INCOMPATIBILITIES iptables/iptables.xslt

	# All the iptables binaries are in /sbin, so might as well
	# put these small files in with them
	into /
	dosbin iptables/iptables-apply
	dosym iptables-apply /sbin/ip6tables-apply
	doman iptables/iptables-apply.8

	insinto /usr/include
	doins include/ip{,6}tables.h
	insinto /usr/include/iptables
	doins include/iptables/internal.h

	keepdir /var/lib/ip{,6}tables
	newinitd "${FILESDIR}"/${PN}-r3.init iptables
	newconfd "${FILESDIR}"/${PN}-r1.confd iptables
	dosym iptables /etc/init.d/ip6tables
	newconfd "${FILESDIR}"/ip6tables-r1.confd ip6tables

	if use nftables; then
		# Bug #647458
		rm "${ED}"/etc/ethertypes || die

		# Bugs #660886 and #669894
		# Flatcar: We don't provide arptables* binaries.
		# Flatcar: Keeping the ebtables binaries
		rm "${ED}"/sbin/arptables{{,-{save,restore}},-nft{,-{save,restore}}} || die
	fi

	# Flatcar: Gentoo upstream dropped the iptables & ip6tables services
	# but we continue to ship them
	systemd_dounit "${FILESDIR}"/systemd/ip{,6}tables{,-{re,}store}.service

	# Move important libs to /lib, bug #332175
	gen_usr_ldscript -a ip{4,6}tc xtables

	find "${ED}" -type f -name "*.la" -delete || die
}

pkg_postinst() {
	# Flatcar: Use xtables-nft-multi to use the nft backend instead of legacy backend
	local default_iptables="xtables-nft-multi"
	if ! eselect iptables show &>/dev/null; then
		elog "Current iptables implementation is unset, setting to ${default_iptables}"
		eselect iptables set "${default_iptables}"
	fi
	# Flatcar: Drop the arptables, but retain the `for` structure in favor of lesser diff
	# to upstream
	if use nftables; then
		local tables
		for tables in ebtables; do
			if ! eselect ${tables} show &>/dev/null; then
				elog "Current ${tables} implementation is unset, setting to ${default_iptables}"
				eselect ${tables} set "${default_iptables}"
			fi
		done
	fi

	eselect iptables show
}

pkg_prerm() {
	if [[ -z ${REPLACED_BY_VERSION} ]]; then
		elog "Unsetting iptables symlinks before removal"
		eselect iptables unset
	fi

	if ! has_version 'net-firewall/ebtables'; then
		elog "Unsetting ebtables symlinks before removal"
		eselect ebtables unset
	fi

	# The eselect module failing should not be fatal
	return 0
}
