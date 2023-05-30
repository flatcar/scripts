# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="flatcar/baselayout"
CROS_WORKON_LOCALNAME="baselayout"
CROS_WORKON_REPO="https://github.com"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
else
	CROS_WORKON_COMMIT="a482cb4b69ffa5cf92d9cd719409e7abd7f382a3" # flatcar-master
	KEYWORDS="amd64 arm arm64 x86"
fi

TMPFILES_OPTIONAL=1
inherit cros-workon multilib systemd tmpfiles

DESCRIPTION="Filesystem baselayout for CoreOS"
HOMEPAGE="http://www.coreos.com/"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
IUSE="cros_host symlink-usr"

# This version of baselayout replaces coreos-base
DEPEND="sys-apps/systemd
	net-dns/libidn2:=
	!coreos-base/coreos-base
	!<sys-libs/glibc-2.17-r1
	!<=sys-libs/nss-usrfiles-2.18.1_pre"

# Make sure coreos-init is not installed in the SDK
RDEPEND="${DEPEND}
	>=sys-apps/gentoo-functions-0.10
	cros_host? ( !coreos-base/coreos-init )"

MOUNT_POINTS=(
	/dev
	/proc
	/sys
)

declare -A USR_SYMS		# list of /foo->usr/foo symlinks
declare -a BASE_DIRS	# list of absolute paths that should be directories

# Check that a pre-existing symlink is correct
check_sym() {
	local path="$1" value="$2"
	local real_path=$(readlink -f "${ROOT}${path}")
	local real_value=$(readlink -f "${ROOT}${path%/*}/${value}")
	if [[ -e "${read_path}" && "${read_path}" != "${read_value}" ]]; then
		die "${path} is not a symlink to ${value}"
	fi
}

pkg_setup() {
	local libdirs=$(get_all_libdirs)

	if [[ -z "${libdirs}" ]]; then
		die "your DEFAULT_ABI=$DEFAULT_ABI appears to be invalid"
	fi

	# figure out which paths should be symlinks and which should be directories
	local d
	for d in bin sbin ${libdirs} ; do
		if use symlink-usr; then
			USR_SYMS["/$d"]="usr/$d"
			BASE_DIRS+=( "/usr/$d" "/usr/local/$d" )
		else
			BASE_DIRS+=( "/$d" "/usr/$d" "/usr/local/$d" )
		fi
	done

	# make sure any pre-existing symlinks map to the expected locations.
	local sym
	if use symlink-usr; then
		for sym in "${!USR_SYMS[@]}" ; do
			check_sym "${sym}" "${USR_SYMS[$sym]}"
		done
	fi
}

src_compile() {
	default

	# generate a tmpfiles.d config to cover our /usr symlinks
	if use symlink-usr; then
		local tmpfiles="${T}/baselayout-usr.conf"
		echo -n > ${tmpfiles} || die
		for sym in "${!USR_SYMS[@]}" ; do
			echo "L+	${sym}	-	-	-	-	${USR_SYMS[$sym]}" >> ${tmpfiles}
		done
	fi
}

src_install() {
	dodir "${BASE_DIRS[@]}"

	if use cros_host; then
		# Since later systemd-tmpfiles --root is used only users from
		# /etc/passwd are considered but we don't want to add core there
		# because it would make emerge overwrite the system's database on
		# installation when the SDK user is already there. Instead, just
		# create the folder manually and remove the tmpfile directive.
		rm "${S}/tmpfiles.d/baselayout-home.conf"
		mkdir -p "${D}"/home/core
		chown 500:500 "${D}"/home/core
	else
		# Initialize /etc/passwd, group, and friends now, so
		# systemd-tmpfiles can resolve user information in ${D}
		# rootfs.
		bash "scripts/flatcar-tmpfiles" "${D}" "${S}/baselayout" || die
	fi

	if use symlink-usr; then
		dotmpfiles "${T}/baselayout-usr.conf"
		systemd-tmpfiles --root="${D}" --create
	fi

	emake DESTDIR="${D}" install

	# Fill in all other paths defined in tmpfiles configs
	systemd-tmpfiles --root="${D}" --create

	# The above created a few mount points but leave those out of the
	# package since they may be mounted read-only. postinst can make them.
	local mnt
	for mnt in "${MOUNT_POINTS[@]}"; do
		rmdir "${D}${mnt}" || die
	done

	doenvd "env.d/99flatcar_ldpath"

	# handle multilib paths.  do it here because we want this behavior
	# regardless of the C library that you're using.  we do explicitly
	# list paths which the native ldconfig searches, but this isn't
	# problematic as it doesn't change the resulting ld.so.cache or
	# take longer to generate.  similarly, listing both the native
	# path and the symlinked path doesn't change the resulting cache.
	local libdir ldpaths
	for libdir in $(get_all_libdirs) ; do
		ldpaths+=":/${libdir}:/usr/${libdir}:/usr/local/${libdir}"
	done
	echo "LDPATH='${ldpaths#:}'" >> "${D}"/etc/env.d/00basic || die

	# Add oem/lib64 to search path towards end of the system's list.
	# This simplifies the configuration of OEMs with dynamic libs.
	ldpaths=
	for libdir in $(get_all_libdirs) ; do
		ldpaths+=":/oem/${libdir}"
	done
	echo "LDPATH='${ldpaths#:}'" >> "${D}"/etc/env.d/80oem || die

	if ! use symlink-usr ; then
		# modprobe uses /lib instead of /usr/lib
		mv "${D}"/usr/lib/modprobe.d "${D}"/lib/modprobe.d || die
	fi

	if use arm64; then
		sed -i 's/ sss//' "${D}"/usr/share/baselayout/nsswitch.conf || die
	fi

	if use cros_host; then
		# Provided by vim in the SDK
		rm -r "${D}"/etc/vim || die
		# Undesirable in the SDK
		rm "${D}"/etc/profile.d/flatcar-profile.sh || die
	else
		# Don't install /etc/issue since it is handled by coreos-init right now
		rm "${D}"/etc/issue || die
		sed -i -e '/\/etc\/issue/d' \
			"${D}"/usr/lib/tmpfiles.d/baselayout-etc.conf || die

		# Initialize /etc/passwd, group, and friends on boot.
		dosbin "scripts/flatcar-tmpfiles"
		systemd_dounit "scripts/flatcar-tmpfiles.service"
		systemd_enable_service sysinit.target flatcar-tmpfiles.service
	fi

	# sssd not yet building on arm64
	if use arm64; then
		sed -i -e '/pam_sss.so/d' "${D}"/usr/lib/pam.d/* || die
	fi
}

pkg_postinst() {
	# best-effort creation of mount points
	local mnt
	for mnt in "${MOUNT_POINTS[@]}"; do
		[[ -d "${ROOT}${mnt}" ]] || mkdir "${ROOT}${mnt}"
	done
	# Set up /usr/lib/debug to match the root filesystem layout
	# FIXME: This is done in postinst right now and all errors are ignored
	# as a transitional scheme, this isn't important enough to migrate
	# existing SDK environments.
	local dir
	for dir in "${BASE_DIRS[@]}"; do
		mkdir -p "${ROOT}/usr/lib/debug/${dir}"
	done
	if use symlink-usr; then
		for sym in "${!USR_SYMS[@]}" ; do
			ln -sfT "${USR_SYMS[$sym]}" "${ROOT}/usr/lib/debug/${sym}"
		done
	fi
	# The default passwd/group files must exist in the SDK for some ebuilds
	if use cros_host; then
		touch "${ROOT}/etc/"{group,gshadow,passwd,shadow}
		chmod 640 "${ROOT}/etc/"{gshadow,shadow}
	fi
	# compat symlink for packages that haven't migrated to gentoo-functions
	local func=../../lib/gentoo/functions.sh
	if [[ "$(readlink "${ROOT}/etc/init.d/functions.sh")" != "${func}" ]]; then
		elog "Creating /etc/init.d/functions.sh symlink..."
		mkdir -p "${ROOT}/etc/init.d"
		ln -sf "${func}" "${ROOT}/etc/init.d/functions.sh"
	fi
	# install compat symlinks in production images, not in SDK
	# os-release symlink is set up in scripts
	if ! use cros_host; then
		local compat libdir
		for compat in systemd kernel modprobe.d pam pam.d sysctl.d udev ; do
			for libdir in $(get_all_libdirs) ; do
				if [[ "${libdir}" == 'lib' ]]; then continue; fi
				ln -sfT "../lib/${compat}" "${ROOT}/usr/${libdir}/${compat}"
			done
		done
		# Create a compatibility symlink for OEM.
		ln -sfT ../../oem "${ROOT}/usr/share/oem"
		# Also create the directory to avoid having dangling
		# symlinks.
		mkdir -p "${ROOT}/oem"
	fi
}
