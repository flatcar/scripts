# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

TMPFILES_OPTIONAL=1
inherit autotools linux-info systemd tmpfiles

DESCRIPTION="NFS client and server daemons"
HOMEPAGE="http://linux-nfs.org/"

if [[ "${PV}" = *_rc* ]] ; then
	MY_PV="$(ver_rs 1- -)"
	SRC_URI="http://git.linux-nfs.org/?p=steved/nfs-utils.git;a=snapshot;h=refs/tags/${PN}-${MY_PV};sf=tgz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}-${PN}-${MY_PV}"
else
	SRC_URI="mirror://sourceforge/nfs/${P}.tar.bz2"
	KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~mips ppc ppc64 ~riscv ~s390 sparc x86"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="caps ipv6 junction kerberos ldap +libmount nfsdcld +nfsidmap +nfsv4 nfsv41 sasl selinux tcpd +uuid"
REQUIRED_USE="kerberos? ( nfsv4 )"
RESTRICT="test" #315573

# kth-krb doesn't provide the right include
# files, and nfs-utils doesn't build against heimdal either,
# so don't depend on virtual/krb.
# (04 Feb 2005 agriffis)
COMMON_DEPEND="
	dev-db/sqlite:3
	dev-libs/libxml2
	net-libs/libtirpc:=
	>=net-nds/rpcbind-0.2.4
	sys-fs/e2fsprogs
	caps? ( sys-libs/libcap )
	ldap? (
		net-nds/openldap
		sasl? (
			app-crypt/mit-krb5
			dev-libs/cyrus-sasl:2
		)
	)
	libmount? ( sys-apps/util-linux )
	nfsv4? (
		dev-libs/libevent:=
		>=sys-apps/keyutils-1.5.9:=
		kerberos? (
			>=net-libs/libtirpc-0.2.4-r1[kerberos]
			app-crypt/mit-krb5
		)
	)
	nfsv41? (
		sys-fs/lvm2
	)
	tcpd? ( sys-apps/tcp-wrappers )
	uuid? ( sys-apps/util-linux )"
DEPEND="${COMMON_DEPEND}
	elibc_musl? ( sys-libs/queue-standalone )
"
RDEPEND="${COMMON_DEPEND}
	!net-libs/libnfsidmap
	!net-nds/portmap
	!<sys-apps/openrc-0.13.9
	selinux? (
		sec-policy/selinux-rpc
		sec-policy/selinux-rpcbind
	)
"
BDEPEND="
	net-libs/rpcsvc-proto
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}"/${PN}-2.5.2-no-werror.patch
	# Upstream, see bug #808183
	"${FILESDIR}"/${P}-kernel-5.3-nfsv4.patch
)

pkg_setup() {
	linux-info_pkg_setup
	if use nfsv4 && ! use nfsdcld && linux_config_exists && ! linux_chkconfig_present CRYPTO_MD5 ; then
		ewarn "Your NFS server will be unable to track clients across server restarts!"
		ewarn "Please enable the \"${HILITE}nfsdcld${NORMAL}\" USE flag to install the nfsdcltrack usermode"
		ewarn "helper upcall program, or enable ${HILITE}CONFIG_CRYPTO_MD5${NORMAL} in your kernel to"
		ewarn "support the legacy, in-kernel client tracker."
	fi
}

src_prepare() {
	default

	sed \
		-e "/^sbindir/s:= := \"${EPREFIX}\":g" \
		-i utils/*/Makefile.am || die

	eautoreconf
}

src_configure() {
	export libsqlite3_cv_is_recent=yes # Our DEPEND forces this.
	export ac_cv_header_keyutils_h=$(usex nfsidmap)

	# SASL is consumed in a purely automagic way
	export ac_cv_header_sasl_h=no
	export ac_cv_header_sasl_sasl_h=$(usex sasl)

	local myeconfargs=(
		--disable-static
		--with-statedir="${EPREFIX}"/var/lib/nfs
		--enable-tirpc
		--with-tirpcinclude="${ESYSROOT}"/usr/include/tirpc/
		--with-pluginpath="${EPREFIX}"/usr/$(get_libdir)/libnfsidmap
		--with-rpcgen
		--with-systemd="$(systemd_get_systemunitdir)"
		--without-gssglue
		$(use_enable caps)
		$(use_enable ipv6)
		$(use_enable junction)
		$(use_enable kerberos gss)
		$(use_enable kerberos svcgss)
		$(use_enable ldap)
		$(use_enable libmount libmount-mount)
		$(use_enable nfsdcld nfsdcltrack)
		$(use_enable nfsv4)
		$(use_enable nfsv41)
		$(use_enable uuid)
		$(use_with tcpd tcp-wrappers)
	)
	econf "${myeconfargs[@]}"
}

src_compile() {
	# remove compiled files bundled in the tarball
	emake clean
	default
}

src_install() {
	default
	rm linux-nfs/Makefile* || die
	dodoc -r linux-nfs README

	# Don't overwrite existing xtab/etab, install the original
	# versions somewhere safe...  more info in pkg_postinst
	keepdir /var/lib/nfs/{,sm,sm.bak}
	mv "${ED}"/var/lib/nfs "${ED}"/usr/$(get_libdir)/ || die

	if use nfsv4 && use nfsidmap ; then
		insinto /etc
		doins support/nfsidmap/idmapd.conf

		# Install a config file for idmappers in newer kernels. #415625
		insinto /etc/request-key.d
		echo 'create id_resolver * * /usr/sbin/nfsidmap -t 600 %k %d' > id_resolver.conf
		doins id_resolver.conf
	fi

	dotmpfiles "${FILESDIR}"/nfs-utils.conf

	# Provide an empty xtab for compatibility with the old tmpfiles config.
	touch "${ED}"/usr/$(get_libdir)/nfs/xtab

	# Maintain compatibility with the old gentoo systemd unit names, since nfs-utils has units upstream now.
	dosym nfs-server.service "$(systemd_get_systemunitdir)"/nfsd.service
	dosym nfs-idmapd.service "$(systemd_get_systemunitdir)"/rpc-idmapd.service
	dosym nfs-mountd.service "$(systemd_get_systemunitdir)"/rpc-mountd.service
}
