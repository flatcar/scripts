# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lang/go/go-1.0.3.ebuild,v 1.1 2012/10/29 15:57:40 williamh Exp $

EAPI=4

export CTARGET=${CTARGET:-${CHOST}}

inherit bash-completion-r1 elisp-common eutils

if [[ ${PV} = 9999 ]]; then
	EHG_REPO_URI="https://go.googlecode.com/hg"
	inherit mercurial
else
	SRC_URI="http://go.googlecode.com/files/go${PV}.src.tar.gz"
	# Upstream only supports go on amd64, arm and x86 architectures.
	KEYWORDS="-* ~amd64 ~arm ~x86"
fi

DESCRIPTION="A concurrent garbage collected and typesafe programming language"
HOMEPAGE="http://www.golang.org"

LICENSE="BSD"
SLOT="0"
IUSE="bash-completion emacs vim-syntax zsh-completion"

DEPEND="sys-apps/ed"
RDEPEND="bash-completion? ( app-shells/bash-completion )
	emacs? ( virtual/emacs )
	vim-syntax? ( || ( app-editors/vim app-editors/gvim ) )
	zsh-completion? ( app-shells/zsh-completion )"

	# The go language stores binary data for packages in *.a files.
	# These are _NOT_ libraries, and should not be stripped.
STRIP_MASK="/usr/lib/go/pkg/linux*/*.a"

if [[ ${PV} != 9999 ]]; then
	S="${WORKDIR}"/go
fi

src_prepare()
{
	if [[ ${PV} != 9999 ]]; then
		epatch "${FILESDIR}"/${P}-hardened.patch
	fi
	epatch_user
}

src_compile()
{
	export GOROOT_FINAL=/usr/lib/go
	export GOROOT="$(pwd)"
	export GOBIN="${GOROOT}/bin"
	if [[ $CTARGET = armv5* ]]
	then
		export GOARM=5
	fi

	cd src
	./make.bash || die "build failed"
	cd ..

	if use emacs; then
		elisp-compile misc/emacs/*.el
	fi
}

src_test()
{
	cd src
	PATH="${GOBIN}:${PATH}" \
		./run.bash --no-rebuild --banner || die "tests failed"
}

src_install()
{
	dobin bin/*
	dodoc AUTHORS CONTRIBUTORS PATENTS README

	dodir /usr/lib/go
	insinto /usr/lib/go

	# There is a known issue which requires the source tree to be installed [1].
	# Once this is fixed, we can consider using the doc use flag to control
	# installing the doc and src directories.
	# [1] http://code.google.com/p/go/issues/detail?id=2775
	doins -r doc include lib pkg src

	if use bash-completion; then
		dobashcomp misc/bash/go
	fi

	if use emacs; then
		elisp-install ${PN} misc/emacs/*.el misc/emacs/*.elc
	fi

	if use vim-syntax; then
		insinto /usr/share/vim/vimfiles
		doins -r misc/vim/ftdetect
		doins -r misc/vim/ftplugin
		doins -r misc/vim/syntax
		doins -r misc/vim/plugin
		doins -r misc/vim/indent
	fi

	if use zsh-completion; then
		insinto /usr/share/zsh/site-functions
		doins misc/zsh/go
	fi

	fperms -R +x /usr/lib/go/pkg/tool
}

pkg_postinst()
{
	if use emacs; then
		elisp-site-regen
	fi

	# If the go tool sees a package file timestamped older than a dependancy it
	# will rebuild that file.  So, in order to stop go from rebuilding lots of
	# packages for every build we need to fix the timestamps.  The compiler and
	# linker are also checked - so we need to fix them too.
	ebegin "fixing timestamps to avoid unnecessary rebuilds"
	tref="usr/lib/go/pkg/*/runtime.a"
	find "${ROOT}"usr/lib/go -type f \
		-exec touch -r "${ROOT}"${tref} {} \;
	eend $?
}

pkg_postrm()
{
	if use emacs; then
		elisp-site-regen
	fi
}
