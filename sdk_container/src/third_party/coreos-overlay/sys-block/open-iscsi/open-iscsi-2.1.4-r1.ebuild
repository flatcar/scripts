# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools linux-info flag-o-matic toolchain-funcs udev systemd

DESCRIPTION="A performant, transport independent, multi-platform implementation of RFC3720"
HOMEPAGE="http://www.open-iscsi.com/"
SRC_URI="https://github.com/${PN}/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0/0.2"
KEYWORDS="~alpha amd64 arm arm64 ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86"
IUSE="debug infiniband libressl +tcp rdma systemd"

DEPEND="
	sys-apps/kmod
	sys-block/open-isns:=
	sys-kernel/linux-headers
	infiniband? ( sys-fabric/ofed )
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl:0= )
	systemd? ( sys-apps/systemd )
"
RDEPEND="${DEPEND}
	sys-fs/lsscsi
	sys-apps/util-linux"
BDEPEND="virtual/pkgconfig"

REQUIRED_USE="infiniband? ( rdma ) || ( rdma tcp )"

PATCHES=(
	"${FILESDIR}/${PN}-2.1.1-Makefiles.patch"
)

pkg_setup() {
	linux-info_pkg_setup

	# Flatcar: use ewarn instead of die
	if kernel_is -lt 2 6 16; then
		ewarn "Sorry, your kernel must be 2.6.16-rc5 or newer!"
	fi

	# Needs to be done, as iscsid currently only starts, when having the iSCSI
	# support loaded as module. Kernel builtin options don't work. See this for
	# more information:
	# https://groups.google.com/group/open-iscsi/browse_thread/thread/cc10498655b40507/fd6a4ba0c8e91966
	# If there's a new release, check whether this is still valid!
	CONFIG_MODULES="SCSI_ISCSI_ATTRS ISCSI_TCP"
	if linux_config_exists; then
		for module in ${CONFIG_CHECK_MODULES}; do
			linux_chkconfig_module ${module} || ewarn "${module} needs to be built as module (builtin doesn't work)"
		done
	fi
}

src_prepare() {
	sed -e 's:^\(iscsid.startup\)\s*=.*:\1 = /usr/sbin/iscsid:' \
		-i etc/iscsid.conf || die
	sed -e 's:^node.startup = manual:node.startup = automatic:' \
	     -i etc/iscsid.conf || die
	default

	pushd iscsiuio >/dev/null || die
	eautoreconf
	popd >/dev/null || die
}

src_configure() {
	use debug && append-cppflags -DDEBUG_TCP -DDEBUG_SCSI
	append-lfs-flags
}

src_compile() {
	use debug && append-flags -DDEBUG_TCP -DDEBUG_SCSI

	CFLAGS="" \
	emake \
		OPTFLAGS="${CFLAGS} ${CPPFLAGS} $(usex systemd '' -DNO_SYSTEMD)" \
		AR="$(tc-getAR)" CC="$(tc-getCC)" \
		$(usex systemd '' NO_SYSTEMD=1) \
		user
}

src_install() {
	emake DESTDIR="${D}" sbindir="/usr/sbin" install
	# Upstream make is not deterministic, per bug #601514
	rm -f "${D}"/etc/initiatorname.iscsi

	dodoc README THANKS

	docinto test/
	dodoc $(find test -maxdepth 1 -type f ! -name ".*")

	local unit
	local units=(
		iscsi.service
		iscsid.{service,socket}
		iscsiuio.{service,socket}
	)
	for unit in ${units[@]} ; do
		systemd_dounit etc/systemd/${unit}
	done
	systemd_dounit "${FILESDIR}"/iscsi-init.service
	systemd_dotmpfilesd "${FILESDIR}"/open-iscsi.conf

	fperms 600 /etc/iscsi/iscsid.conf
	rm "${D}"/etc/iscsi/initiatorname.iscsi
	mv "${D}"/etc/iscsi "${D}"/usr/share/iscsi
}
