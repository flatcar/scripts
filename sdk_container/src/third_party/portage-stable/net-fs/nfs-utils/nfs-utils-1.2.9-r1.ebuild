# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-fs/nfs-utils/nfs-utils-1.2.9-r1.ebuild,v 1.2 2014/01/18 05:56:45 vapier Exp $

EAPI="4"

inherit eutils flag-o-matic multilib autotools systemd

DESCRIPTION="NFS client and server daemons"
HOMEPAGE="http://linux-nfs.org/"
SRC_URI="mirror://sourceforge/nfs/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="caps ipv6 kerberos +libmount nfsdcld +nfsidmap +nfsv4 nfsv41 selinux tcpd +uuid"
RESTRICT="test" #315573

# kth-krb doesn't provide the right include
# files, and nfs-utils doesn't build against heimdal either,
# so don't depend on virtual/krb.
# (04 Feb 2005 agriffis)
DEPEND_COMMON="tcpd? ( sys-apps/tcp-wrappers )
	caps? ( sys-libs/libcap )
	sys-libs/e2fsprogs-libs
	>=net-nds/rpcbind-0.2.0-r1
	net-libs/libtirpc
	libmount? ( sys-apps/util-linux )
	nfsdcld? ( >=dev-db/sqlite-3.3 )
	nfsv4? (
		>=dev-libs/libevent-1.0b
		>=net-libs/libnfsidmap-0.21-r1
		kerberos? (
			net-libs/librpcsecgss
			>=net-libs/libgssglue-0.3
			net-libs/libtirpc[kerberos]
			app-crypt/mit-krb5
		)
		nfsidmap? (
			>=net-libs/libnfsidmap-0.24
			sys-apps/keyutils
		)
	)
	nfsv41? (
		sys-fs/lvm2
	)
	selinux? (
		sec-policy/selinux-rpc
		sec-policy/selinux-rpcbind
	)
	uuid? ( sys-apps/util-linux )"
RDEPEND="${DEPEND_COMMON} !net-nds/portmap"
DEPEND="${DEPEND_COMMON}
	virtual/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.1.4-mtab-sym.patch
	epatch "${FILESDIR}"/${PN}-1.2.8-cross-build.patch
	eautoreconf
}

src_configure() {
	export libsqlite3_cv_is_recent=yes # Our DEPEND forces this.
	export ac_cv_header_keyutils_h=$(usex nfsidmap)
	econf \
		--with-statedir=/var/lib/nfs \
		--enable-tirpc \
		$(use_enable libmount libmount-mount) \
		$(use_with tcpd tcp-wrappers) \
		$(use_enable nfsdcld nfsdcltrack) \
		$(use_enable nfsv4) \
		$(use_enable nfsv41) \
		$(use_enable ipv6) \
		$(use_enable caps) \
		$(use_enable uuid) \
		$(usex nfsv4 "$(use_enable kerberos gss)" "--disable-gss") \
		$(usex nfsv4 "$(use_with kerberos gssglue)" "--without-gssglue")
}

src_compile(){
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
	mv "${ED}"/var/lib "${ED}"/usr/$(get_libdir) || die

	# Install some client-side binaries in /sbin
	dodir /sbin
	mv "${ED}"/usr/sbin/rpc.statd "${ED}"/sbin/ || die

	if use nfsv4 && use nfsidmap ; then
		# Install a config file for idmappers in newer kernels. #415625
		insinto /etc/request-key.d
		echo 'create id_resolver * * /usr/sbin/nfsidmap -t 600 %k %d' > id_resolver.conf
		doins id_resolver.conf
	fi

	insinto /etc
	doins "${FILESDIR}"/exports

	local f list=() opt_need=""
	if use nfsv4 ; then
		opt_need="rpc.idmapd"
		list+=( rpc.idmapd rpc.pipefs )
		use kerberos && list+=( rpc.gssd rpc.svcgssd )
	fi
	for f in nfs nfsmount rpc.statd "${list[@]}" ; do
		newinitd "${FILESDIR}"/${f}.initd ${f}
	done
	for f in nfs nfsmount ; do
		newconfd "${FILESDIR}"/${f}.confd ${f}
	done
	sed -i \
		-e "/^NFS_NEEDED_SERVICES=/s:=.*:=\"${opt_need}\":" \
		"${ED}"/etc/conf.d/nfs || die #234132
	systemd_dounit "${FILESDIR}"/nfsd.service
	systemd_newunit "${FILESDIR}"/rpc-statd.service-r1 rpc-statd.service
	systemd_dounit "${FILESDIR}"/rpc-mountd.service
}

pkg_postinst() {
	# Install default xtab and friends if there's none existing.  In
	# src_install we put them in /usr/lib/nfs for safe-keeping, but
	# the daemons actually use the files in /var/lib/nfs.  #30486
	local f
	mkdir -p "${ROOT}"/var/lib/nfs #368505
	for f in "${ROOT}"/usr/$(get_libdir)/nfs/*; do
		[[ -e ${ROOT}/var/lib/nfs/${f##*/} ]] && continue
		einfo "Copying default ${f##*/} from /usr/$(get_libdir)/nfs to /var/lib/nfs"
		cp -pPR "${f}" "${ROOT}"/var/lib/nfs/
	done
}
