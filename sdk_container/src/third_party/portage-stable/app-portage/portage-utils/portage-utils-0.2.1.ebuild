# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-portage/portage-utils/portage-utils-0.2.1.ebuild,v 1.2 2009/12/05 10:02:49 vapier Exp $

inherit toolchain-funcs eutils

DESCRIPTION="small and fast portage helper tools written in C"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE=""

src_unpack() {
	unpack ${A}
	cd "${S}"
	sed -i -e 's:\[\[:[:' -e 's:\]\]:]:' Makefile
}

src_compile() {
	tc-export CC
	emake || die
}

src_install() {
	emake install DESTDIR="${D}" || die
}

pkg_postinst() {
	[ -e "${ROOT}"/etc/portage/bin/post_sync ] && return 0
	mkdir -p "${ROOT}"/etc/portage/bin/

cat <<__EOF__ > "${ROOT}"/etc/portage/bin/post_sync
#!/bin/sh
# Copyright 2006-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

if [ -d /etc/portage/postsync.d/ ]; then
	for f in /etc/portage/postsync.d/* ; do
		if [ -x \${f} ] ; then
			\${f}
		fi
	done
else
	:
fi
__EOF__
	chmod 755 "${ROOT}"/etc/portage/bin/post_sync
	if [ ! -e "${ROOT}"/etc/portage/postsync.d/q-reinitialize ]; then
		mkdir -p "${ROOT}"/etc/portage/postsync.d/
		echo '[ -x /usr/bin/q ] && /usr/bin/q -qr' > "${ROOT}"/etc/portage/postsync.d/q-reinitialize
		elog "${ROOT}/etc/portage/postsync.d/q-reinitialize has been installed for convenience"
		elog "If you wish for it to be automatically run at the end of every --sync simply chmod +x ${ROOT}/etc/portage/postsync.d/q-reinitialize"
		elog "Normally this should only take a few seconds to run but file systems such as ext3 can take a lot longer."
		elog "If ever you find this to be an inconvenience simply chmod -x ${ROOT}/etc/portage/postsync.d/q-reinitialize"
	fi
	:
}
