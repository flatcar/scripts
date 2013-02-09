# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/jdk/jdk-1.6.0.ebuild,v 1.23 2011/11/07 16:05:27 caster Exp $

DESCRIPTION="Virtual for JDK"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="1.6"
KEYWORDS="amd64 ppc ppc64 x86 ~ppc-aix ~x86-fbsd ~x64-freebsd ~hppa-hpux ~ia64-hpux ~amd64-linux ~x86-linux ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE=""

# The keyword voodoo below is needed so that ppc(64) users will
# get a masked license warning for ibm-jdk-bin
# instead of (not useful) missing keyword warning for sun-jdk
# see #287615
# note that this "voodoo" is pretty annoying for Prefix, and that we didn't
# invent it in the first place!

COMMON_INC="
		=dev-java/ibm-jdk-bin-1.6.0*
		=dev-java/hp-jdk-bin-1.6.0*
		=dev-java/diablo-jdk-1.6.0*
		=dev-java/soylatte-jdk-bin-1.0*
		=dev-java/apple-jdk-bin-1.6.0*
		=dev-java/winjdk-bin-1.6.0*
"

# icedtea-bin-1* is old versioning scheme of icedtea-bin-6*
X86_OPTS="|| (
		=dev-java/icedtea-bin-6*
		=dev-java/icedtea-bin-1*
		=dev-java/icedtea-6*
		=dev-java/sun-jdk-1.6.0*
		${COMMON_INC}
	)"

X86_PREFIX_OPTS="|| (
		=dev-java/icedtea-bin-6*
		=dev-java/icedtea-bin-1*
		=dev-java/sun-jdk-1.6.0*
		${COMMON_INC}
	)"

PPC_OPTS="|| (
		=dev-java/ibm-jdk-bin-1.6.0*
		=dev-java/icedtea-6*
	)"

COMMON_OPTS="|| (
		${COMMON_INC}
		)"

RDEPEND="|| (
		amd64? ( ${X86_OPTS} )
		x86? ( ${X86_OPTS} )
		ppc? ( ${PPC_OPTS} )
		ppc64? ( ${PPC_OPTS} )
		amd64-linux? ( ${X86_PREFIX_OPTS} )
		x86-linux? ( ${X86_PREFIX_OPTS} )
		x64-solaris? ( ${X86_PREFIX_OPTS} )
		x86-solaris? ( ${X86_PREFIX_OPTS} )
		sparc-solaris? ( ${X86_PREFIX_OPTS} )
		sparc64-solaris? ( ${X86_PREFIX_OPTS} )
		!amd64? ( !x86? ( !ppc? ( !ppc64? ( !amd64-linux? ( !x86-linux? ( !x64-solaris? ( !x86-solaris? ( !sparc-solaris? ( !sparc64-solaris? (
			${COMMON_OPTS}
		) ) ) ) ) ) ) ) ) )
	)"
DEPEND=""
