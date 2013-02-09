# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/jdk/jdk-1.5.0.ebuild,v 1.21 2012/09/16 13:17:36 chithanh Exp $

DESCRIPTION="Virtual for JDK"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="1.5"
KEYWORDS="amd64 ~arm ppc ppc64 x86 ~ppc-aix ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

# The keyword voodoo below is needed so that ppc(64) users will
# get a masked license warning for ibm-jdk-bin
# instead of (not useful) missing keyword warning for sun-jdk
# see #287615
# note that this "voodoo" is pretty annoying for Prefix, and that we didn't
# invent it in the first place!
RDEPEND="|| (
		amd64? ( =dev-java/sun-jdk-1.5.0* )
		x86? ( =dev-java/sun-jdk-1.5.0* )
		amd64-linux? ( =dev-java/sun-jdk-1.5.0* )
		x86-linux? ( =dev-java/sun-jdk-1.5.0* )
		x64-solaris? ( =dev-java/sun-jdk-1.5.0* )
		x86-solaris? ( =dev-java/sun-jdk-1.5.0* )
		sparc-solaris? ( =dev-java/sun-jdk-1.5.0* )
		sparc64-solaris? ( =dev-java/sun-jdk-1.5.0* )
		=dev-java/ibm-jdk-bin-1.5.0*
		=dev-java/jrockit-jdk-bin-1.5.0*
		=dev-java/apple-jdk-bin-1.5.0*
		dev-java/gcj-jdk
	)"
DEPEND=""
