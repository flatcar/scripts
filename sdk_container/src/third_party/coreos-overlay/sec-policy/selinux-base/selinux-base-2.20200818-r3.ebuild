# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

# flatcar changes
PYTHON_COMPAT=( python3_{8,9,10,11} )
PYTHON_REQ_USE="xml(+)"
TMPFILES_OPTIONAL=1
inherit systemd tmpfiles python-any-r1

if [[ ${PV} == 9999* ]]; then
	EGIT_REPO_URI="${SELINUX_GIT_REPO:-https://anongit.gentoo.org/git/proj/hardened-refpolicy.git}"
	EGIT_BRANCH="${SELINUX_GIT_BRANCH:-master}"
	EGIT_CHECKOUT_DIR="${WORKDIR}/refpolicy"

	inherit git-r3
else
	SRC_URI="https://github.com/SELinuxProject/refpolicy/releases/download/RELEASE_${PV/./_}/refpolicy-${PV}.tar.bz2
			https://dev.gentoo.org/~perfinion/patches/selinux-base-policy/patchbundle-selinux-base-policy-${PV}-r2.tar.bz2"

	KEYWORDS="amd64 -arm ~arm64 ~mips x86"
fi

IUSE="doc +unknown-perms systemd +ubac +unconfined"

DESCRIPTION="Gentoo base policy for SELinux"
HOMEPAGE="https://wiki.gentoo.org/wiki/Project:SELinux"
LICENSE="GPL-2"
SLOT="0"

# flatcar changes
RDEPEND=">=sys-apps/policycoreutils-2.8
	>=sys-apps/checkpolicy-2.8
"
DEPEND="${RDEPEND}"
# flatcar: BDEPEND on python - normally pulled in through policycoreutils
# but we made that dep conditional on USE=python
BDEPEND="sys-devel/m4
    ${PYTHON_DEPS}
"


# flatcar changes
PATCHES=(
	"${FILESDIR}"/0001-policy-modules-kernel-all-more-actions-for-kernel.patch
	"${FILESDIR}"/0001-policy-ms-MCS-restricts-relabelfrom.patch
	"${FILESDIR}"/icmp-bind.patch
)

S=${WORKDIR}/

src_prepare() {
	if [[ ${PV} != 9999* ]]; then
		einfo "Applying SELinux policy updates ... "
		eapply -p0 "${WORKDIR}/0001-full-patch-against-stable-release.patch"
	fi

	# flatcar changes
	eapply -p0 "${PATCHES[@]}"
	eapply_user

	cd "${S}/refpolicy" || die
	emake bare
}

src_configure() {
	[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="targeted strict mls mcs"

	# Update the SELinux refpolicy capabilities based on the users' USE flags.
	if use unknown-perms; then
		sed -i -e '/^UNK_PERMS/s/deny/allow/' "${S}/refpolicy/build.conf" \
			|| die "Failed to allow Unknown Permissions Handling"
		sed -i -e '/^UNK_PERMS/s/deny/allow/' "${S}/refpolicy/Makefile" \
			|| die "Failed to allow Unknown Permissions Handling"
	fi

	if ! use ubac; then
		sed -i -e '/^UBAC/s/y/n/' "${S}/refpolicy/build.conf" \
			|| die "Failed to disable User Based Access Control"
	fi

	if use systemd; then
		sed -i -e '/^SYSTEMD/s/n/y/' "${S}/refpolicy/build.conf" \
			|| die "Failed to enable SystemD"
	fi

	echo "DISTRO = gentoo" >> "${S}/refpolicy/build.conf" || die

	# Prepare initial configuration
	cd "${S}/refpolicy" || die
	emake conf

	# Setup the policies based on the types delivered by the end user.
	# These types can be "targeted", "strict", "mcs" and "mls".
	for i in ${POLICY_TYPES}; do
		cp -a "${S}/refpolicy" "${S}/${i}" || die
		cd "${S}/${i}" || die

		sed -i -e "/= module/d" "${S}/${i}/policy/modules.conf" || die

		# flatcar changes: it's required to run polkit without segfault
		# we need to pass this argument now before the compilation of the policy
		sed -i "s/allow_execmem = false/allow_execmem = true/" "${S}/${i}/policy/booleans.conf" || die

		sed -i -e '/^QUIET/s/n/y/' -e "/^NAME/s/refpolicy/$i/" \
			"${S}/${i}/build.conf" || die "build.conf setup failed."

		if [[ "${i}" == "mls" ]] || [[ "${i}" == "mcs" ]];
		then
			# MCS/MLS require additional settings
			sed -i -e "/^TYPE/s/standard/${i}/" "${S}/${i}/build.conf" \
				|| die "failed to set type to mls"
		fi

		if [ "${i}" == "targeted" ]; then
			sed -i -e '/root/d' -e 's/user_u/unconfined_u/' \
			"${S}/${i}/config/appconfig-standard/seusers" \
			|| die "targeted seusers setup failed."
		fi

		if [ "${i}" != "targeted" ] && [ "${i}" != "strict" ] && use unconfined; then
			sed -i -e '/root/d' -e 's/user_u/unconfined_u/' \
			"${S}/${i}/config/appconfig-${i}/seusers" \
			|| die "policy seusers setup failed."
		fi
	done
}

src_compile() {
	[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="targeted strict mls mcs"

	for i in ${POLICY_TYPES}; do
		cd "${S}/${i}" || die
		# flatcar changes
		emake base BINDIR="${ROOT}/usr/bin" NAME=$i SHAREDIR="${ROOT%/}"/usr/share/selinux \
			LD_LIBRARY_PATH="${ROOT}/usr/lib64:${LD_LIBRARY_PATH}" -C "${S}"/${i}
		if use doc; then
			emake html
		fi
	done
}

src_install() {
	[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="targeted strict mls mcs"

	for i in ${POLICY_TYPES}; do
		cd "${S}/${i}" || die

		emake DESTDIR="${D}" install
		emake DESTDIR="${D}" install-headers

		echo "run_init_t" > "${D}/etc/selinux/${i}/contexts/run_init_type" || die

		echo "textrel_shlib_t" >> "${D}/etc/selinux/${i}/contexts/customizable_types" || die

		# libsemanage won't make this on its own
		keepdir "/etc/selinux/${i}/policy"

		if use doc; then
			docinto ${i}/html
			dodoc -r doc/html/*;
		fi

		insinto /usr/share/selinux/devel;
		doins doc/policy.xml;

	done

	# flatcar changes
	dotmpfiles "${FILESDIR}/tmpfiles.d/selinux-base.conf"
	systemd-tmpfiles --root="${D}" --create selinux-base.conf

	docinto /
	dodoc doc/Makefile.example doc/example.{te,fc,if}

	doman man/man8/*.8;

	# flatcar changes
	insinto /usr/lib/selinux
	doins "${FILESDIR}/config"

	insinto /etc/selinux/mcs/contexts
	doins "${FILESDIR}/lxc_contexts"

	# flatcar changes
	mkdir -p "${D}/usr/lib/selinux"
	for i in ${POLICY_TYPES}; do
		mv "${D}/etc/selinux/${i}" "${D}/usr/lib/selinux"
		dosym "../../usr/lib/selinux/${i}" "/etc/selinux/${i}"
	done

	insinto /usr/share/portage/config/sets
	doins "${FILESDIR}/selinux.conf"
}
