# Copyright (c) 2013 The CoreOS Authors. All rights reserved.
# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGIT_REPO_URI="https://github.com/flatcar/init.git"

if [[ "${PV}" == 9999 ]]; then
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
else
	EGIT_COMMIT="dd9cbe449efb7134f885b07b16425eb51fb808a8" # flatcar-master
	KEYWORDS="amd64 arm arm64 x86"
fi

PYTHON_COMPAT=( python3_{9..11} )

inherit git-r3 systemd python-any-r1

DESCRIPTION="Init scripts for CoreOS"
HOMEPAGE="http://www.coreos.com/"
SRC_URI=""

LICENSE="BSD"
SLOT="0/${PVR}"
IUSE="test openssh"

# Daemons we enable here must installed during build/install in addition to
# during runtime so the systemd unit enable step works.
DEPEND="
	openssh? ( net-misc/openssh )
	net-nds/rpcbind
	!coreos-base/oem-service
	test? ( ${PYTHON_DEPS} )
	"
RDEPEND="${DEPEND}
	app-admin/logrotate
	sys-block/parted
	sys-apps/gptfdisk
	>=sys-apps/systemd-207-r5
	>=coreos-base/coreos-cloudinit-0.1.2-r5
	"

src_install() {
	emake DESTDIR="${D}" install

	# Enable some services that aren't enabled elsewhere.
	systemd_enable_service rpcbind.target rpcbind.service

	# Create compatibility symlinks in case /usr/lib64/ instead of /usr/lib/ was used
	local compat
	for compat in modules flatcar coreos ; do
		dosym "../lib/${compat}" "/usr/lib64/${compat}"
	done

  # Flatcar NANO HACK ALERT
  # Remove openssh helper scripts and services if we don't ship openssh
  if ! use openssh; then
    local sshfile
    for sshfile in \
      "${D}/usr/lib/systemd/system/sshd@.service.d" \
      "${D}/usr/lib/systemd/system/sshkeys.service" \
      "${D}/usr/lib/systemd/system/multi-user.target.wants/sshkeys.service" \
      "${D}/usr/lib/systemd/system/sshd-keygen.service" \
      "${D}/usr/lib/systemd/system/multi-user.target.wants/sshd-keygen.service" \
      "${D}/usr/lib/systemd/system/ssh-key-proc-cmdline.service" \
      "${D}/usr/lib/systemd/system/multi-user.target.wants/ssh-key-proc-cmdline.service" \
      "${D}/usr/lib/systemd/system/update-ssh-keys-after-ignition.service" \
      "${D}/usr/lib/systemd/system/multi-user.target.wants/update-ssh-keys-after-ignition.service" \
      "${D}//usr/lib/flatcar/sshd_keygen" \
      "${D}//usr/lib/flatcar/ssh-key-proc-cmdline" \
      ; do
         einfo "openssh USE flag not set, removing SSH helper scripts and services"
        rm -rvf "${sshfile}"
    done
  fi
}
