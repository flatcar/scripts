# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-fs/nfs-utils/nfs-utils-1.1.4-r1.ebuild,v 1.10 2010/03/31 18:06:59 solar Exp $

inherit eutils flag-o-matic multilib

DESCRIPTION="NFS client and server daemons"
HOMEPAGE="http://linux-nfs.org/"
SRC_URI="mirror://sourceforge/nfs/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86"
IUSE="nonfsv4 tcpd kerberos elibc_glibc"

# kth-krb doesn't provide the right include
# files, and nfs-utils doesn't build against heimdal either,
# so don't depend on virtual/krb.
# (04 Feb 2005 agriffis)
RDEPEND="tcpd? ( sys-apps/tcp-wrappers )
	sys-libs/e2fsprogs-libs
	>=net-nds/portmap-5b-r6
	!nonfsv4? (
		>=dev-libs/libevent-1.0b
		>=net-libs/libnfsidmap-0.21-r1
		kerberos? (
			net-libs/librpcsecgss
			net-libs/libgssglue
			app-crypt/mit-krb5
		)
	)"
# util-linux dep is to prevent man-page collision
DEPEND="${RDEPEND}
	>=sys-apps/util-linux-2.12r-r7"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-1.1.4-rpcgen-ioctl.patch
	epatch "${FILESDIR}"/${PN}-1.1.4-ascii-man.patch
	epatch "${FILESDIR}"/${PN}-1.1.4-mtab-sym.patch
	epatch "${FILESDIR}"/${PN}-1.1.4-no-exec.patch
}

src_compile() {
	local myconf
	if use nonfsv4 ; then
		myconf="--disable-gss"
	else
		myconf="$(use_enable kerberos gss)"
	fi

	econf \
		--mandir=/usr/share/man \
		--with-statedir=/var/lib/nfs \
		--disable-rquotad \
		--enable-nfsv3 \
		--enable-secure-statd \
		$(use_with tcpd tcp-wrappers) \
		$(use_enable !nonfsv4 nfsv4) \
		${myconf} \
		|| die "Configure failed"
	emake || die "Failed to compile"
}

src_install() {
	emake DESTDIR="${D}" install || die

	# Don't overwrite existing xtab/etab, install the original
	# versions somewhere safe...  more info in pkg_postinst
	dodir /usr/lib/nfs
	keepdir /var/lib/nfs/{sm,sm.bak}
	mv "${D}"/var/lib/nfs/* "${D}"/usr/lib/nfs
	keepdir /var/lib/nfs

	# Install some client-side binaries in /sbin
	dodir /sbin
	mv "${D}"/usr/sbin/rpc.statd "${D}"/sbin/ || die

	dodoc ChangeLog README
	docinto linux-nfs ; dodoc linux-nfs/*

	insinto /etc
	doins "${FILESDIR}"/exports

	local f list=""
	if use !nonfsv4 ; then
		list="${list} rpc.idmapd rpc.pipefs"
		use kerberos && list="${list} rpc.gssd rpc.svcgssd"
	fi
	for f in nfs nfsmount rpc.statd ${list} ; do
		newinitd "${FILESDIR}"/${f}.initd ${f} || die "doinitd ${f}"
	done
	newconfd "${FILESDIR}"/nfs.confd nfs

	# uClibc doesn't provide rpcgen like glibc, so lets steal it from nfs-utils
	if ! use elibc_glibc ; then
		dobin tools/rpcgen/rpcgen || die "rpcgen"
		newdoc tools/rpcgen/README README.rpcgen
	fi
}

pkg_postinst() {
	# Install default xtab and friends if there's none existing.
	# In src_install we put them in /usr/lib/nfs for safe-keeping, but
	# the daemons actually use the files in /var/lib/nfs.  This fixes
	# bug 30486
	local f
	for f in "${ROOT}"/usr/$(get_libdir)/nfs/*; do
		[[ -e ${ROOT}/var/lib/nfs/${f##*/} ]] && continue
		einfo "Copying default ${f##*/} from /usr/$(get_libdir)/nfs to /var/lib/nfs"
		cp -pPR "${f}" "${ROOT}"/var/lib/nfs/
	done
}
