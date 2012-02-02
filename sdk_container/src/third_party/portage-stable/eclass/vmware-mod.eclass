# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/vmware-mod.eclass,v 1.18 2009/01/10 12:26:04 ikelos Exp $


# Ensure vmware comes before linux-mod since we want linux-mod's pkg_preinst and
# pkg_postinst, along with our own pkg_setup, src_unpack and src_compile
inherit flag-o-matic eutils vmware linux-mod

DESCRIPTION="Modules for Vmware Programs"
HOMEPAGE="http://www.vmware.com/"
SRC_URI="http://platan.vc.cvut.cz/ftp/pub/vmware/${ANY_ANY}.tar.gz
	http://platan.vc.cvut.cz/ftp/pub/vmware/obsolete/${ANY_ANY}.tar.gz
	http://knihovny.cvut.cz/ftp/pub/vmware/${ANY_ANY}.tar.gz
	http://knihovny.cvut.cz/ftp/pub/vmware/obsolete/${ANY_ANY}.tar.gz
	http://ftp.cvut.cz/vmware/${ANY_ANY}.tar.gz
	http://ftp.cvut.cz/vmware/obsolete/${ANY_ANY}.tar.gz"
LICENSE="vmware"
SLOT="0"
IUSE=""

# Provide vaguely sensible defaults
[[ -z "${VMWARE_VER}" ]] && VMWARE_VER="VME_V55"
VMWARE_MOD_DIR="${ANY_ANY}"

S="${WORKDIR}"

# We needn't restrict this since it was only required to read
# /etc/vmware/locations to determine the version (which is now fixed by
# VMWARE_VER)
# RESTRICT="userpriv"

EXPORT_FUNCTIONS pkg_setup src_unpack src_install

vmware-mod_pkg_setup() {
	linux-mod_pkg_setup
	# Must define VMWARE_VER to make, otherwise it'll try and run getversion.pl
	BUILD_TARGETS="auto-build VMWARE_VER=${VMWARE_VER} KERNEL_DIR=${KERNEL_DIR} KBUILD_OUTPUT=${KV_OUT_DIR}"

	vmware_determine_product
	# We create a group for VMware users due to bugs #104480 and #106170
	enewgroup "${VMWARE_GROUP}"

	if [[ -z "${VMWARE_MODULE_LIST}" ]]; then
		case ${product} in
			vmware-tools)
				VMWARE_MODULE_LIST="${VMWARE_MODULE_LIST} vmxnet"
				[ "$shortname" != "server-tools" ] && VMWARE_MODULE_LIST="${VMWARE_MODULE_LIST} vmhgfs vmmemctl"
				use amd64 || VMWARE_MODULE_LIST="${VMWARE_MODULE_LIST} vmdesched"
				;;
			*)
				VMWARE_MODULE_LIST="${VMWARE_MODULE_LIST} vmmon vmnet"
				;;
		esac
	fi

	filter-flags -mfpmath=sse

	for mod in ${VMWARE_MODULE_LIST}; do
	MODULE_NAMES="${MODULE_NAMES}
				  ${mod}(misc:${S}/${mod}-only)"
	done
}

vmware-mod_src_unpack() {
	case ${product} in
		vmware-tools)
			# Do nothing, this should be dealt with by vmware.eclass unpack
			;;
		*)
			unpack ${A}
			;;
	esac

	for mod in ${VMWARE_MODULE_LIST}; do
		cd "${S}"
		unpack ./"${VMWARE_MOD_DIR}"/${mod}.tar
		cd "${S}"/${mod}-only
		# Ensure it's not used
		# rm getversion.pl
		if [[ "${VMWARE_MOD_DIR}" = "${ANY_ANY}" ]] ; then
			EPATCH_SUFFIX="patch"
			epatch "${FILESDIR}"/patches
			[[ -d "${FILESDIR}"/patches/${mod} ]] && epatch "${FILESDIR}"/patches/${mod}
		fi
		convert_to_m "${S}"/${mod}-only/Makefile
	done
}

vmware-mod_src_install() {
	# this adds udev rules for vmmon*
	if [[ -n "`echo ${VMWARE_MODULE_LIST} | grep vmmon`" ]];
	then
		dodir /etc/udev/rules.d
		echo 'KERNEL=="vmmon*", GROUP="'$VMWARE_GROUP'" MODE=660' >> "${D}/etc/udev/rules.d/60-vmware.rules" || die
		echo 'KERNEL=="vmnet*", GROUP="'$VMWARE_GROUP'" MODE=660' >> "${D}/etc/udev/rules.d/60-vmware.rules" || die
	fi

	linux-mod_src_install
}

# Current VMWARE product mappings
# 'VME_TOT'		= .0
# 'VME_GSX1'	= .1
# 'VME_GSX2'	= .2
# 'VME_GSX251'	= .3
# 'VME_GSX25'	= .4
# 'VME_GSX32'	= .5
# 'VME_V3'		= .6
# 'VME_V32'		= .7
# 'VME_V321'	= .8
# 'VME_V4'		= .9
# 'VME_V45'		= .10
# 'VME_V452'	= .11
# 'VME_V5'		= .12
# 'VME_V55'		= .13
# 'VME_S1B1'	= .14
# 'VME_S1??'	= .15
# 'VME_V6'      = .16
# 'VME_V6'      = .17  (6.0.2)
# 'VME_S2B1'    = .18
