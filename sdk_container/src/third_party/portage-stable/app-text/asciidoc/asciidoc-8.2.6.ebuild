# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/asciidoc/asciidoc-8.2.6.ebuild,v 1.11 2012/09/15 04:31:54 floppym Exp $

DESCRIPTION="A text document format for writing short documents, articles, books and UNIX man pages"
HOMEPAGE="http://www.methods.co.nz/asciidoc/"
SRC_URI="mirror://sourceforge/project/${PN}/${PN}/${PV}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="examples vim-syntax"

DEPEND=">=dev-lang/python-2.3
		dev-libs/libxslt"

src_unpack() {
	unpack ${A}

	sed -i \
		-e "s:^BINDIR=.*:BINDIR=${D}usr/bin:" \
		-e "s:^MANDIR=.*:MANDIR=${D}usr/share/man:" \
		-e "s:^CONFDIR=.*:CONFDIR=${D}etc/asciidoc:" \
		-e "s:^VIM_CONFDIR=.*:VIM_CONFDIR=${D}usr/share/vim/vimfiles:" \
		"${S}/install.sh"
}

src_install() {
	dodir /usr/bin

	use vim-syntax && dodir /usr/share/vim/vimfiles

	"${S}"/install.sh

	if use examples; then
		# This is a symlink to a directory
		rm -f examples/website/images
		cp -Rf images examples/website

		insinto /usr/share/doc/${PF}
		doins -r examples
	fi

	# HTML pages (with their sources)
	dohtml -r doc/*
	insinto /usr/share/doc/${PF}/html
	doins doc/*.txt

	# Misc. documentation
	dodoc BUGS CHANGELOG COPYRIGHT README
	dodoc docbook-xsl/asciidoc-docbook-xsl.txt
}

pkg_preinst() {
	# Clean any symlinks in /etc possibly installed by previous versions
	if [ -d "${ROOT}etc/asciidoc" ]; then
		einfo "Cleaning old symlinks under /etc/asciidoc"
		for entry in $(find "${ROOT}etc/asciidoc" -type l); do
			rm -f $entry
		done
	fi
}
