# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/epic4/epic4-2.10.ebuild,v 1.9 2012/12/23 20:12:41 ulm Exp $

EAPI="2"

inherit flag-o-matic eutils toolchain-funcs

HELP_V="20050315"

DESCRIPTION="Epic4 IRC Client"
HOMEPAGE="http://epicsol.org/"
SRC_URI="ftp://ftp.epicsol.org/pub/epic/EPIC4-PRODUCTION/${P}.tar.bz2
	ftp://prbh.org/pub/epic/EPIC4-PRODUCTION/epic4-help-${HELP_V}.tar.gz
	mirror://gentoo/epic4-local.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc sparc x86"
IUSE="ipv6 perl ssl"

DEPEND=">=sys-libs/ncurses-5.2
	perl? ( >=dev-lang/perl-5.6.1[-ithreads] )
	ssl? ( >=dev-libs/openssl-0.9.5 )"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/epic-defaultserver.patch

	rm -f "${WORKDIR}"/help/Makefile
	find "${WORKDIR}"/help -type d -name CVS -print0 | xargs -0 rm -r
}

src_configure() {
	replace-flags "-O?" "-O"

	econf \
		--libexecdir=/usr/lib/misc \
		$(use_with ipv6) \
		$(use_with perl) \
		$(use_with ssl) \
		|| die "econf failed"
}

src_compile() {
	emake CC="$(tc-getCC)" || die "make failed"
}

src_install () {
	einstall \
		sharedir="${D}"/usr/share \
		libexecdir="${D}"/usr/lib/misc || die "einstall failed"

	dodoc BUG_FORM COPYRIGHT README KNOWNBUGS VOTES

	cd "${S}"/doc
	docinto doc
	dodoc \
		*.txt colors EPIC* IRCII_VERSIONS local_vars missing new-load \
		nicknames outputhelp SILLINESS TS4

	insinto /usr/share/epic/help
	doins -r "${WORKDIR}"/help/* || die "doins failed"
}

pkg_postinst() {
	if [ ! -f "${ROOT}"/usr/share/epic/script/local ]
	then
		elog "/usr/share/epic/script/local does not exist, I will now"
		elog "create it. If you do not like the look/feel of this file, or"
		elog "if you'd prefer to use your own script, simply remove this"
		elog "file.  If you want to prevent this file from being installed"
		elog "in the future, simply create an empty file with this name."
		cp "${WORKDIR}"/epic4-local "${ROOT}"/usr/share/epic/script/local
		elog
		elog "This provided local startup script adds a number of nifty"
		elog "features to Epic including tab completion, a comprehensive set"
		elog "of aliases, and channel-by-channel logging.  To prevent"
		elog "unintentional conflicts with your own scripting, if either the"
		elog "~/.ircrc or ~/.epicrc script files exist, then the local script"
		elog "is *not* run.  If you like the script but want to make careful"
		elog "additions (such as selecting your usual servers or setting your"
		elog "nickname), simply copy /usr/share/epic/script/local to ~/.ircrc"
		elog "and then add your additions to the copy."
	fi

	# Fix for bug 59075
	chmod 755 "${ROOT}"/usr/share/epic/help
}
