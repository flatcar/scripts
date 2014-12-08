# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/profiles/prefix/darwin/macos/10.10/profile.bashrc,v 1.3 2014/11/24 21:38:16 redlizard Exp $

# this is no typo, gcc-apple doesn't allow for 10.10 and mixes things up
export MACOSX_DEPLOYMENT_TARGET=10.9

# some packages need to be compiled with clang on 10.10
local pkgs_clang pkg
pkgs_clang=(
	dev-libs/glib
	dev-lang/python
	sys-devel/binutils-apple
)
for pkg in ${pkgs_clang[@]} ; do
	if [[ ${CATEGORY}/${PN} == ${pkg} ]]; then
		CC="clang -I${EPREFIX}/usr/include"
		CXX="clang++ -I${EPREFIX}/usr/include"
	fi
done
