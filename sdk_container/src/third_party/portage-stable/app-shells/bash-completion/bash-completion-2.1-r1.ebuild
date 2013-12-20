# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-shells/bash-completion/bash-completion-2.1-r1.ebuild,v 1.6 2013/08/25 17:05:36 ssuominen Exp $

EAPI=5

DESCRIPTION="Programmable Completion for bash"
HOMEPAGE="http://bash-completion.alioth.debian.org/"
SRC_URI="http://bash-completion.alioth.debian.org/files/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris"
IUSE=""

RDEPEND="|| ( >=app-shells/bash-4.1 app-shells/zsh )
	sys-apps/miscfiles"

src_test() { :; } # Skip testsuite because of interactive shell wrt #477066

src_install() {
	default

	# use the copies from >=sys-apps/util-linux-2.23 wrt #468544 -> hd and ncal
	# becomes dead symlinks as a result
	local file
	for file in cal dmesg eject hd hexdump hwclock ionice look ncal renice rtcwake; do
		rm -f "${ED}"/usr/share/bash-completion/completions/${file}
	done

	# use the copy from app-editors/vim-core:
	rm -f "${ED}"/usr/share/bash-completion/completions/xxd

	# use the copy from net-misc/networkmanager:
	rm -f "${ED}"/usr/share/bash-completion/completions/nmcli

	dodoc AUTHORS CHANGES README
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog "If you use non-login shells you still need to source"
		elog "/usr/share/bash-completion/bash_completion in your ~/.bashrc."
	else
		ewarn "Please re-emerge all packages on your system which install"
		ewarn "completions in /usr/share/bash-completion."
		ewarn "They should now be in their own completions/ sub directory."
		ewarn
		ewarn "One way to do this is to run the following command:"
		ewarn "emerge -av1 \$(qfile -q -S -C /usr/share/bash-completion)"
		ewarn "Note that qfile can be found in app-portage/portage-utils"
	fi

	if has_version 'app-shells/zsh'; then
		elog
		elog "If you are interested in using the provided bash completion functions with"
		elog "zsh, valuable tips on the effective use of bashcompinit are available:"
		elog "  http://www.zsh.org/mla/workers/2003/msg00046.html"
		elog
	fi
}
