# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

# Tell linux-info where to find the kernel source/build
KERNEL_DIR="${SYSROOT%/}/usr/src/linux"
KBUILD_OUTPUT="${SYSROOT%/}/var/cache/portage/sys-kernel/coreos-kernel"
inherit linux-info savedconfig

# In case this is a real snapshot, fill in commit below.
# For normal, tagged releases, leave blank
MY_COMMIT=

if [[ ${PV} == 99999999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git"
else
	if [[ -n "${MY_COMMIT}" ]]; then
		SRC_URI="https://git.kernel.org/cgit/linux/kernel/git/firmware/linux-firmware.git/snapshot/${MY_COMMIT}.tar.gz -> linux-firmware-${PV}.tar.gz"
	else
		SRC_URI="https://mirrors.edge.kernel.org/pub/linux/kernel/firmware/linux-firmware-${PV}.tar.xz -> linux-firmware-${PV}.tar.xz"
	fi
	KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~mips ppc ppc64 s390 sparc x86"
fi

DESCRIPTION="Linux firmware files"
HOMEPAGE="https://git.kernel.org/?p=linux/kernel/git/firmware/linux-firmware.git"

LICENSE="GPL-2 GPL-2+ GPL-3 BSD MIT || ( MPL-1.1 GPL-2 )
	BSD-2 BSD BSD-4 ISC MIT no-source-code"
SLOT="0"
IUSE="savedconfig"

CDEPEND=">=sys-kernel/coreos-modules-4.6.3-r1:="
DEPEND="${CDEPEND}
		sys-kernel/coreos-sources"
#add anything else that collides to this
RDEPEND="!savedconfig? (
		!sys-firmware/alsa-firmware[alsa_cards_ca0132]
		!sys-firmware/alsa-firmware[alsa_cards_korg1212]
		!sys-firmware/alsa-firmware[alsa_cards_maestro3]
		!sys-firmware/alsa-firmware[alsa_cards_sb16]
		!sys-firmware/alsa-firmware[alsa_cards_ymfpci]
		!net-dialup/ueagle-atm
		!net-dialup/ueagle4-atm
		!sys-block/qla-fc-firmware
		!sys-firmware/iwl1000-ucode
		!sys-firmware/iwl6005-ucode
		!sys-firmware/iwl6030-ucode
		!sys-firmware/iwl6050-ucode
		!sys-firmware/iwl3160-ucode
		!sys-firmware/iwl7260-ucode
		!sys-firmware/iwl3160-7260-bt-ucode
	)"

RESTRICT="binchecks strip"

# source name is linux-firmware, not coreos-firmware
S="${WORKDIR}/linux-firmware-${PV}"

CXGB_VERSION="1.27.3.0"
ICE_DDP_VERSION="1.3.30.0"

src_unpack() {
	if [[ ${PV} == 99999999* ]]; then
		git-r3_src_unpack
	else
		default
		# Upstream linux-firmware tarball does not contain
		# symlinks for cxgb4 firmware files, but "modinfo
		# cxgb4.ko" shows it requires t?fw.bin files. These
		# normally are installed by the copy-firmware.sh
		# script, which refers to the WHENCE file. Both the
		# script and the file are in the tarball. The WHENCE
		# file actually mentions that these symlinks should be
		# created, but apparently our ebuild is not using this
		# way of installing the firmware files, so we need to
		# create the symlinks to avoid failures at the
		# firmware scanning stage.
		ln -sfn t4fw-${CXGB_VERSION}.bin linux-firmware-${PV}/cxgb4/t4fw.bin
		ln -sfn t5fw-${CXGB_VERSION}.bin linux-firmware-${PV}/cxgb4/t5fw.bin
		ln -sfn t6fw-${CXGB_VERSION}.bin linux-firmware-${PV}/cxgb4/t6fw.bin

		# Upstream linux-firmware tarball does not contain
		# a correct symlink to intel/ice/ddp/ice-1.3.28.0.pkg,
		# but "modinfo ice.ko" shows it requires ice.pkg.
		# So we need to create the symlink to avoid failures at the
		# firmware scanning stage.
		ln -sfn ice-${ICE_DDP_VERSION}.pkg linux-firmware-${PV}/intel/ice/ddp/ice.pkg

		# The xhci-pci.ko kernel module started requiring a
		# renesas_usb_fw.mem firmware file, but this file is
		# nowhere to be found in the tarball. So we just fake
		# the existence of the firmware, so the firmware
		# scanning stage won't fail. Obviously, this means
		# that if someone is going to use this specific
		# renesas controller that requires the firmware, it
		# won't work. Hopefully that file appears at some
		# point in the tarball.
		touch "linux-firmware-${PV}/renesas_usb_fw.mem"
	fi
}

src_prepare() {
	local kernel_mods="${SYSROOT%/}/lib/modules/${KV_FULL}"

	# Fail if any firmware is missing.
	einfo "Scanning for files required by ${KV_FULL}"
	echo -n > "${T}/firmware-scan"
	local kofile fwfile failed
	for kofile in $(find "${kernel_mods}" -name '*.ko' -o -name '*.ko.xz'); do
		for fwfile in $(modinfo --field firmware "${kofile}"); do
			if [[ ! -e "${fwfile}" ]]; then
				eerror "Missing firmware: ${fwfile} (${kofile##*/})"
				failed=1
			elif [[ -L "${fwfile}" ]]; then
				echo "${fwfile}" >> "${T}/firmware-scan"
				realpath --relative-to=. "${fwfile}" >> "${T}/firmware-scan"
			else
				echo "${fwfile}" >> "${T}/firmware-scan"
			fi
		done
	done
	if [[ -n "${failed}" ]]; then
		die "Missing firmware"
	fi

	# AMD's microcode is shipped as part of coreos-firmware, but not a dependency to
	# any module, so add it manually
	use amd64 && find amd-ucode/ -type f -not -name "*.asc" >> "${T}/firmware-scan"

	einfo "Pruning all unneeded firmware files..."
	sort -u "${T}/firmware-scan" > "${T}/firmware"
	find * -not -type d \
		| sort "${T}/firmware" "${T}/firmware" - \
		| uniq -u | xargs -r rm
	find * -type f -name "* *" -exec rm -f {} \;

	default

	echo "# Remove files that shall not be installed from this list." > ${PN}.conf
	find * \( \! -type d -and \! -name ${PN}.conf \) >> ${PN}.conf

	if use savedconfig; then
		restore_config ${PN}.conf
		ebegin "Removing all files not listed in config"

		local file delete_file preserved_file preserved_files=()

		while IFS= read -r file; do
			# Ignore comments.
			if [[ ${file} != "#"* ]]; then
				preserved_files+=("${file}")
			fi
		done < ${PN}.conf || die

		while IFS= read -d "" -r file; do
			delete_file=true
			for preserved_file in "${preserved_files[@]}"; do
				if [[ "${file}" == "${preserved_file}" ]]; then
					delete_file=false
				fi
			done

			if ${delete_file}; then
				rm "${file}" || die
			fi
		done < <(find * \( \! -type d -and \! -name ${PN}.conf \) -print0 || die)

		eend || die

		# remove empty directories, bug #396073
		find -type d -empty -delete || die
	fi
}

src_install() {
	# Flatcar: Don't save the firmware config to /etc/portage/savedconfig/
	# if use !savedconfig; then
	# 	save_config ${PN}.conf
	# fi
	rm ${PN}.conf || die
	insinto /lib/firmware/
	doins -r *
}

pkg_preinst() {
	if use savedconfig; then
		ewarn "USE=savedconfig is active. You must handle file collisions manually."
	fi
}

pkg_postinst() {
	elog "If you are only interested in particular firmware files, edit the saved"
	elog "configfile and remove those that you do not want."
}
