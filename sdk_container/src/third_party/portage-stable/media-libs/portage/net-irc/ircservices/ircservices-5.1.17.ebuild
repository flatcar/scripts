# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/ircservices/ircservices-5.1.17.ebuild,v 1.3 2009/12/28 19:01:34 nixnut Exp $

inherit eutils fixheadtails flag-o-matic toolchain-funcs

DESCRIPTION="ChanServ, NickServ & MemoServ with support for several IRC daemons"
HOMEPAGE="http://www.ircservices.za.net/"
SRC_URI="http://www.ircservices.za.net/download/${P}.tar.gz
	ftp://ftp.esper.net/${PN}/${P}.tar.gz
	mirror://gentoo/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ppc x86"
IUSE=""

DEPEND=""
RDEPEND=""

pkg_setup() {
	enewgroup ircservices
	enewuser ircservices -1 -1 -1 ircservices
	# this is needed, because old ebuilds added the user with ircservices:users
	usermod -g ircservices ircservices
}

src_unpack() {
	unpack ${A}
	cd "${S}"

	epatch "${FILESDIR}/${P}-fPIC.patch"
	epatch "${FILESDIR}/${P}-fPIC-configure.patch"

	ht_fix_file configure
	sed -i \
		-e "s/-m 750/-m 755/" \
		-e "s/-m 640/-m 644/" \
		configure
	#bug 273978
	sed -i -e "s/getline/get_line/" lang/langcomp.c
}

src_compile() {
	append-flags -fno-stack-protector
	# configure fails with -O higher than 2
	replace-flags "-O[3-9s]" "-O2"

	RUNGROUP="ircservices" \
	./configure \
		-cc "$(tc-getCC)" \
		-cflags "${CFLAGS}" \
		-bindest /usr/bin \
		-datdest /var/lib/ircservices \
		|| die "./configure failed"
	emake -j1 || die "make failed"
}

src_install() {
	dodir /usr/bin /{etc,usr/{$(get_libdir),share},var/lib}/ircservices || die "dodir failed"
	keepdir /var/log/ircservices || die "keepdir failed"

	make \
		BINDEST="${D}"/usr/bin \
		DATDEST="${D}"/var/lib/ircservices \
		install \
		|| die "make install failed"

	mv "${D}"/var/lib/ircservices/convert-db "${D}"/usr/bin/ircservices-convert-db || die "mv failed"

	# Now we move some files around to make it FHS conform
	mv "${D}"/var/lib/ircservices/example-ircservices.conf "${D}"/etc/ircservices/ircservices.conf || die "mv failed"
	dosym /etc/ircservices/ircservices.conf /var/lib/ircservices/ircservices.conf || die "dosym failed"

	mv "${D}"/var/lib/ircservices/example-modules.conf "${D}"/etc/ircservices/modules.conf || die "mv failed"
	dosym /etc/ircservices/modules.conf /var/lib/ircservices/modules.conf || die "dosym failed"

	mv "${D}"/var/lib/ircservices/modules "${D}"/usr/$(get_libdir)/ircservices || die "mv failed"
	dosym /usr/$(get_libdir)/ircservices/modules /var/lib/ircservices/modules || die "dosym failed"

	mv "${D}"/var/lib/ircservices/{helpfiles,languages} "${D}"/usr/share/ircservices  || die "mv failed"
	dosym /usr/share/ircservices/helpfiles /var/lib/ircservices/helpfiles || die "mv failed"
	dosym /usr/share/ircservices/languages /var/lib/ircservices/languages || die "dosym failed"

	fperms 750 /var/{lib,log}/ircservices /etc/ircservices
	fperms 640 /etc/ircservices/{ircservices,modules}.conf
	fowners ircservices:ircservices /var/{lib,log}/ircservices
	fowners root:ircservices /etc/ircservices{,/{ircservices,modules}.conf}

	newinitd "${FILESDIR}"/ircservices.init.d ircservices || die "newinitd failed"
	newconfd "${FILESDIR}"/ircservices.conf.d ircservices || die "newconfd failed"

	doman docs/ircservices.8 || die "doman failed"
	newman docs/convert-db.8 ircservices-convert-db.8 || die "newman failed"
	dohtml docs/*.html || die "dohtml failed"
	dodoc docs/Changes README docs/WhatsNew || die "dodoc failed"
}
