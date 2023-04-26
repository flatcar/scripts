# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGO_PN=github.com/docker/docker
GIT_COMMIT=78021fea1789da0de7b0b0b161f8a10b93586f43
COREOS_GO_VERSION="go1.18"
COREOS_GO_GO111MODULE="off"

inherit bash-completion-r1 linux-info systemd udev golang-vcs-snapshot
inherit coreos-go-depend

DESCRIPTION="The core functions you need to create Docker images and run Docker containers"
HOMEPAGE="https://www.docker.com/"
MY_PV=${PV/_/-}
SRC_URI="https://github.com/moby/moby/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ~arm arm64 ppc64 ~x86"
# Flatcar: default enable required USE flags
IUSE="apparmor aufs +btrfs +cli +container-init +device-mapper +hardened +overlay +seccomp +journald"

DEPEND="
	acct-group/docker
	>=dev-db/sqlite-3.7.9:3
	apparmor? ( sys-libs/libapparmor )
	btrfs? ( >=sys-fs/btrfs-progs-3.16.1 )
	device-mapper? ( >=sys-fs/lvm2-2.02.89[thin] )
	seccomp? ( >=sys-libs/libseccomp-2.2.1 )
"

# Flatcar:
# For CoreOS builds coreos-kernel must be installed because this ebuild
# checks the kernel config. The kernel config is left by the kernel compile
# or an explicit copy when installing binary packages. See coreos-kernel.eclass
DEPEND+="sys-kernel/coreos-kernel"

# https://github.com/moby/moby/blob/master/project/PACKAGERS.md#runtime-dependencies
# https://github.com/moby/moby/blob/master/project/PACKAGERS.md#optional-dependencies
# https://github.com/moby/moby/tree/master//hack/dockerfile/install
# make sure docker-proxy is pinned to exact version from ^,
# for appropriate branchch/version of course
# Flatcar:
# containerd ebuild doesn't support apparmor, device-mapper and seccomp use flags
# tini ebuild doesn't support static use flag
RDEPEND="
	${DEPEND}
	>=net-firewall/iptables-1.4
	sys-process/procps
	>=dev-vcs/git-1.7
	>=app-arch/xz-utils-4.9
	dev-libs/libltdl
	>=app-emulation/containerd-1.4.6[btrfs?]
	~app-emulation/docker-proxy-0.8.0_p20210525
	cli? ( app-emulation/docker-cli )
	container-init? ( >=sys-process/tini-0.19.0 )
"

# https://github.com/docker/docker/blob/master/project/PACKAGERS.md#build-dependencies
# Flatcar: drop go-md2man
BDEPEND="
	>=dev-lang/go-1.13.12
	virtual/pkgconfig
"
# tests require running dockerd as root and downloading containers
RESTRICT="installsources strip test"

S="${WORKDIR}/${P}/src/${EGO_PN}"

PATCHES=(
	"${FILESDIR}/ppc64-buildmode.patch"
)

# see "contrib/check-config.sh" from upstream's sources
CONFIG_CHECK="
	~NAMESPACES ~NET_NS ~PID_NS ~IPC_NS ~UTS_NS
	~CGROUPS ~CGROUP_CPUACCT ~CGROUP_DEVICE ~CGROUP_FREEZER ~CGROUP_SCHED ~CPUSETS ~MEMCG
	~CGROUP_NET_PRIO
	~KEYS
	~VETH ~BRIDGE ~BRIDGE_NETFILTER
	~IP_NF_FILTER ~IP_NF_TARGET_MASQUERADE ~NETFILTER_XT_MARK
	~NETFILTER_NETLINK ~NETFILTER_XT_MATCH_ADDRTYPE ~NETFILTER_XT_MATCH_CONNTRACK ~NETFILTER_XT_MATCH_IPVS
	~IP_NF_NAT ~NF_NAT
	~POSIX_MQUEUE

	~USER_NS
	~SECCOMP
	~CGROUP_PIDS
	~MEMCG_SWAP

	~BLK_CGROUP ~BLK_DEV_THROTTLING
	~CGROUP_PERF
	~CGROUP_HUGETLB
	~NET_CLS_CGROUP
	~CFS_BANDWIDTH ~FAIR_GROUP_SCHED
	~IP_VS ~IP_VS_PROTO_TCP ~IP_VS_PROTO_UDP ~IP_VS_NFCT ~IP_VS_RR

	~VXLAN
	~CRYPTO ~CRYPTO_AEAD ~CRYPTO_GCM ~CRYPTO_SEQIV ~CRYPTO_GHASH ~XFRM_ALGO ~XFRM_USER
	~IPVLAN
	~MACVLAN ~DUMMY

	~OVERLAY_FS ~!OVERLAY_FS_REDIRECT_DIR
	~EXT4_FS_SECURITY
	~EXT4_FS_POSIX_ACL
"

ERROR_KEYS="CONFIG_KEYS: is mandatory"
ERROR_MEMCG_SWAP="CONFIG_MEMCG_SWAP: is required if you wish to limit swap usage of containers"
ERROR_RESOURCE_COUNTERS="CONFIG_RESOURCE_COUNTERS: is optional for container statistics gathering"

ERROR_BLK_CGROUP="CONFIG_BLK_CGROUP: is optional for container statistics gathering"
ERROR_IOSCHED_CFQ="CONFIG_IOSCHED_CFQ: is optional for container statistics gathering"
ERROR_CGROUP_PERF="CONFIG_CGROUP_PERF: is optional for container statistics gathering"
ERROR_CFS_BANDWIDTH="CONFIG_CFS_BANDWIDTH: is optional for container statistics gathering"
ERROR_XFRM_ALGO="CONFIG_XFRM_ALGO: is optional for secure networks"
ERROR_XFRM_USER="CONFIG_XFRM_USER: is optional for secure networks"

pkg_setup() {

	if kernel_is lt 4 5; then
		CONFIG_CHECK+="
			~MEMCG_KMEM
		"
		ERROR_MEMCG_KMEM="CONFIG_MEMCG_KMEM: is optional"
	fi

	if kernel_is lt 4 7; then
		CONFIG_CHECK+="
			~DEVPTS_MULTIPLE_INSTANCES
		"
	fi

	if kernel_is lt 5 1; then
		CONFIG_CHECK+="
			~NF_NAT_IPV4
			~IOSCHED_CFQ
			~CFQ_GROUP_IOSCHED
		"
	fi

	if kernel_is lt 5 2; then
		CONFIG_CHECK+="
			~NF_NAT_NEEDED
		"
	fi

	if kernel_is lt 5 8; then
		CONFIG_CHECK+="
			~MEMCG_SWAP_ENABLED
		"
	fi

	if use aufs; then
		CONFIG_CHECK+="
			~AUFS_FS
			~EXT4_FS_POSIX_ACL ~EXT4_FS_SECURITY
		"
		ERROR_AUFS_FS="CONFIG_AUFS_FS: is required to be set if and only if aufs is patched to kernel instead of using standalone"
	fi

	if use btrfs; then
		CONFIG_CHECK+="
			~BTRFS_FS
			~BTRFS_FS_POSIX_ACL
		"
	fi

	if use device-mapper; then
		CONFIG_CHECK+="
			~BLK_DEV_DM ~DM_THIN_PROVISIONING ~EXT4_FS ~EXT4_FS_POSIX_ACL ~EXT4_FS_SECURITY
		"
	fi

	linux-info_pkg_setup
}

src_compile() {
	# Flatcar: for cross-compilation
	go_export
	export DOCKER_GITCOMMIT="${GIT_COMMIT}"
	export GOPATH="${WORKDIR}/${P}"
	export VERSION=${PV}

	# setup CFLAGS and LDFLAGS for separate build target
	# see https://github.com/tianon/docker-overlay/pull/10
	# Flatcar: allow injecting CFLAGS/LDFLAGS, which is needed for torcx rpath
	export CGO_CFLAGS="${CGO_CFLAGS} -I${ESYSROOT}/usr/include"
	export CGO_LDFLAGS="${CGO_LDFLAGS} -L${ESYSROOT}/usr/$(get_libdir)"

	# let's set up some optional features :)
	export DOCKER_BUILDTAGS=''
	for gd in aufs btrfs device-mapper overlay; do
		if ! use $gd; then
			DOCKER_BUILDTAGS+=" exclude_graphdriver_${gd//-/}"
		fi
	done

	for tag in apparmor seccomp journald; do
		if use $tag; then
			DOCKER_BUILDTAGS+=" $tag"
		fi
	done

	# Flatcar:
	# inject LDFLAGS for torcx
	if use hardened; then
		sed -i "s#EXTLDFLAGS_STATIC='#&-fno-PIC $LDFLAGS #" hack/make.sh || die
		grep -q -- '-fno-PIC' hack/make.sh || die 'hardened sed failed'
		sed  "s#LDFLAGS_STATIC_DOCKER='#&-extldflags \"-fno-PIC $LDFLAGS\" #" \
			-i hack/make/dynbinary-daemon || die
		grep -q -- '-fno-PIC' hack/make/dynbinary-daemon || die 'hardened sed failed'
	fi

	# build daemon
	./hack/make.sh dynbinary || die 'dynbinary failed'
}

src_install() {
	dosym containerd /usr/bin/docker-containerd
	dosym containerd-shim /usr/bin/docker-containerd-shim
	dosym runc /usr/bin/docker-runc
	use container-init && dosym tini /usr/bin/docker-init
	newbin bundles/dynbinary-daemon/dockerd dockerd

	newinitd contrib/init/openrc/docker.initd docker
	newconfd contrib/init/openrc/docker.confd docker

	# Flatcar:
	# install our systemd units/network config and our wrapper into
	# /usr/lib/flatcar/docker for backwards compatibility
	exeinto /usr/lib/flatcar
	doexe "${FILESDIR}/dockerd"

	systemd_dounit "${FILESDIR}/docker.service"
	systemd_dounit "${FILESDIR}/docker.socket"

	insinto /usr/lib/systemd/network
	doins "${FILESDIR}/50-docker.network"
	doins "${FILESDIR}/90-docker-veth.network"

	udev_dorules contrib/udev/*.rules

	dodoc AUTHORS CONTRIBUTING.md CHANGELOG.md NOTICE README.md
	dodoc -r docs/*

	# Flatcar:
	# don't install contrib bits
}

pkg_postinst() {
	udev_reload

	elog
	elog "To use Docker, the Docker daemon must be running as root. To automatically"
	elog "start the Docker daemon at boot:"
	if systemd_is_booted || has_version sys-apps/systemd; then
		elog "  systemctl enable docker.service"
	else
		elog "  rc-update add docker default"
	fi
	elog
	elog "To use Docker as a non-root user, add yourself to the 'docker' group:"
	elog '  usermod -aG docker <youruser>'
	elog

	if use device-mapper; then
		elog " Devicemapper storage driver has been deprecated"
		elog " It will be removed in a future release"
		elog
	fi

	if use overlay; then
		elog " Overlay storage driver/USEflag has been deprecated"
		elog " in favor of overlay2 (enabled unconditionally)"
		elog
	fi

	if has_version sys-fs/zfs; then
		elog " ZFS storage driver is available"
		elog " Check https://docs.docker.com/storage/storagedriver/zfs-driver for more info"
		elog
	fi

	if use cli; then
		ewarn "Starting with docker 20.10.2, docker has been split into"
		ewarn "two packages upstream, so Gentoo has followed suit."
		ewarn
		ewarn "app-emulation/docker contains the daemon and"
		ewarn "app-emulation/docker-cli contains the docker command."
		ewarn
		ewarn "docker currently installs docker-cli using the cli use flag."
		ewarn
		ewarn "This use flag is temporary, so you need to take the"
		ewarn "following actions:"
		ewarn
		ewarn "First, disable the cli use flag for app-emulation/docker"
		ewarn
		ewarn "Then, if you need docker-cli and docker on the same machine,"
		ewarn "run the following command:"
		ewarn
		ewarn "# emerge --noreplace docker-cli"
		ewarn
	fi
}
