# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/jdk/jdk-1.6.0.ebuild,v 1.18 2010/03/04 23:47:11 caster Exp $

DESCRIPTION="Virtual for JDK"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="1.6"
KEYWORDS="amd64 ppc ppc64 x86 ~ppc-aix ~x86-fbsd ~hppa-hpux ~ia64-hpux ~amd64-linux ~x86-linux ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE=""

# Keeps this and java-virtuals/jaf in sync
# The keyword voodoo below is needed so that ppc(64) users will
# get a masked license warning for ibm-jdk-bin
# instead of (not useful) missing keyword warning for sun-jdk
# see #287615
# note that this "voodoo" is pretty annoying for Prefix, and that we didn't
# invent it in the first place!
RDEPEND="|| (
		amd64? ( dev-java/icedtea6-bin )
		x86? ( dev-java/icedtea6-bin )
		amd64-linux? ( dev-java/icedtea6-bin )
		x86-linux? ( dev-java/icedtea6-bin )
		amd64? ( =dev-java/icedtea-6* )
		x86? ( =dev-java/icedtea-6* )
		amd64? ( =dev-java/sun-jdk-1.6.0* )
		x86? ( =dev-java/sun-jdk-1.6.0* )
		amd64-linux? ( =dev-java/sun-jdk-1.6.0* )
		x86-linux? ( =dev-java/sun-jdk-1.6.0* )
		x64-solaris? ( =dev-java/sun-jdk-1.6.0* )
		x86-solaris? ( =dev-java/sun-jdk-1.6.0* )
		sparc-solaris? ( =dev-java/sun-jdk-1.6.0* )
		sparc64-solaris? ( =dev-java/sun-jdk-1.6.0* )
		=dev-java/ibm-jdk-bin-1.6.0*
		=dev-java/hp-jdk-bin-1.6.0*
		=dev-java/diablo-jdk-1.6.0*
		=dev-java/soylatte-jdk-bin-1.0*
		=dev-java/apple-jdk-bin-1.6.0*
		=dev-java/winjdk-bin-1.6.0*
	)"
DEPEND=""
