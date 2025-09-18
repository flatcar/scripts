# Copyright (c) The Flatcar Maintainers
# Distributed under the terms of the GNU General Public License v2


EAPI=7

DESCRIPTION="Flatcar Nano image(meta package)"
HOMEPAGE="http://flatcar.org"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="selinux"

# Force rebuild to hon0r new use flags (see ../../profiles/coreos/base/package.use.force)
BDEPEND="
  	net-misc/curl
    >=sys-apps/baselayout-3.0.0
    sys-boot/shim
    sys-boot/grub
"

# Optionally enable SELinux for dbus and systemd (but always install packages and pull in the SELinux policy for containers)
RDEPEND="${RDEPEND}
  >=sys-apps/baselayout-3.0.0
	sys-apps/dbus[selinux?]
	sys-apps/systemd[selinux?]
	"

# Only applicable or available on amd64
RDEPEND="${RDEPEND}
	amd64? (
		app-emulation/xenserver-pv-version
		app-emulation/xenstore
	)"

# Removed 
#	app-admin/etcd-wrapper
#	app-admin/flannel-wrapper
#	app-admin/locksmith
#	app-admin/sdnotify-proxy
#	app-admin/sudo
#	app-admin/toolbox
#	app-alternatives/awk
#	app-arch/gzip
#	app-arch/bzip2
#	app-arch/lbzip2
#	app-arch/lz4
#	app-arch/pigz
#	app-arch/xz-utils
#	app-arch/zstd
#	app-arch/tar
#	app-arch/unzip
#	app-arch/zip
#	app-arch/ncompress
#	app-crypt/adcli
#	app-editors/vim
#	app-containers/cri-tools
#   app-misc/jq
#	app-misc/pax-utils
#	app-shells/bash
#	coreos-base/update-ssh-keys
#	coreos-base/update_engine
#	dev-db/etcdctl
#	dev-debug/strace
#	dev-libs/libsodium
#	dev-libs/openssl
#	dev-util/bpftool
#	dev-util/bsdiff
#	dev-vcs/git
#	net-analyzer/openbsd-netcat
#	net-analyzer/tcpdump
#	net-analyzer/traceroute
#	net-dns/bind
#	net-fs/nfs-utils
#	net-fs/cifs-utils
#	net-misc/ntp
#	net-misc/rsync
#	net-misc/socat
#	net-misc/wget
#	net-misc/whois
#	net-vpn/wireguard-tools
#	sys-apps/acl
#	sys-apps/attr
# sys-apps/azure-vm-utils  -- This should go into the Azure OEM sysext?
#	sys-apps/coreutils
#	sys-apps/diffutils
#	sys-apps/ethtool
#	sys-apps/findutils
#	sys-apps/grep
#	sys-apps/kexec-tools
#	sys-apps/less
#	sys-apps/lshw
#	sys-apps/usbutils
#	sys-apps/which
#	amd64? (
#		sys-auth/google-oslogin   -- This should go into the Google OEM sysext?
#	)
#	sys-auth/realmd
#	sys-auth/sssd
#	sys-boot/mokutil
#	sys-devel/gettext
#	sys-fs/dosfstools
#	sys-fs/lsscsi
#	sys-fs/quota
#	sys-libs/glibc
#	sys-power/acpid
#	sys-process/lsof
#	sys-process/procps
#	x11-drivers/nvidia-drivers-service


# coreos-metadata (and probably others) need 'sed'.
# Early boot needs 'net-tools' on some platforms.

RDEPEND="${RDEPEND}
	app-admin/mayday
	app-crypt/clevis
	app-crypt/gnupg
	app-crypt/go-tspi
	app-crypt/tpmpolicy
	app-emulation/qemu-guest-agent
	app-misc/ca-certificates
	coreos-base/afterburn
	coreos-base/coreos-cloudinit
	coreos-base/coreos-init
	coreos-base/misc-files
	coreos-base/ue-rs
	net-firewall/conntrack-tools
	net-firewall/ebtables
	net-firewall/ipset
	net-firewall/iptables
	net-firewall/nftables
	net-libs/nghttp2
	net-misc/bridge-utils
	net-misc/curl
	net-misc/iputils
	sec-policy/selinux-base
	sec-policy/selinux-base-policy
	sec-policy/selinux-container
	sec-policy/selinux-dbus
	sec-policy/selinux-policykit
	sec-policy/selinux-unconfined
	sys-apps/checkpolicy
	sys-apps/dbus
	sys-apps/gptfdisk
	sys-apps/ignition
	sys-apps/iproute2
	sys-apps/keyutils
	sys-apps/net-tools
	sys-apps/nvme-cli
	sys-apps/pciutils
	sys-apps/policycoreutils
	sys-apps/sed
	sys-apps/seismograph
	sys-apps/semodule-utils
	sys-apps/shadow
	sys-apps/util-linux
	sys-apps/zram-generator
	sys-block/open-iscsi
	sys-block/parted
	sys-boot/efibootmgr
	sys-cluster/ipvsadm
	sys-fs/btrfs-progs
	sys-fs/cryptsetup
	sys-fs/e2fsprogs
	sys-fs/lvm2
	sys-fs/mdadm
	sys-fs/multipath-tools
	sys-fs/xfsprogs
	sys-kernel/coreos-firmware
	sys-kernel/coreos-kernel
	sys-libs/nss-usrfiles
	sys-libs/timezone-data
"
