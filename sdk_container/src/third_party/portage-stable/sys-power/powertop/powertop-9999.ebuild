# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-power/powertop/powertop-9999.ebuild,v 1.16 2012/11/22 15:00:37 zerochaos Exp $

EAPI="4"

inherit eutils linux-info
if [ ${PV} == "9999" ] ; then
	EGIT_REPO_URI="git://github.com/fenrus75/powertop.git"
	inherit git-2 autotools
	SRC_URI=""
else
	SRC_URI="https://01.org/powertop/sites/default/files/downloads/${P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~ppc ~sparc ~x86 ~amd64-linux ~x86-linux"
fi

DESCRIPTION="tool that helps you find what software is using the most power"
HOMEPAGE="https://01.org/powertop/ http://www.lesswatts.org/projects/powertop/"

LICENSE="GPL-2"
SLOT="0"
IUSE="unicode X"

COMMON_DEPEND="
	dev-libs/libnl:3
	sys-apps/pciutils
	sys-devel/gettext
	sys-libs/ncurses[unicode?]
"

DEPEND="${COMMON_DEPEND}
	virtual/pkgconfig
"
RDEPEND="
	${COMMON_DEPEND}
	X? ( x11-apps/xset )
"

DOCS=( TODO README )

pkg_setup() {
	if linux_config_exists; then
		CONFIG_CHECK="
			~X86_MSR
			~DEBUG_FS
			~PERF_EVENTS
			~TRACEPOINTS
			~NO_HZ
			~HIGH_RES_TIMERS
			~HPET_TIMER
			~CPU_FREQ_STAT
			~CPU_FREQ_GOV_ONDEMAND
			~USB_SUSPEND
			~FTRACE
			~BLK_DEV_IO_TRACE
			~TIMER_STATS
			~EVENT_POWER_TRACING_DEPRECATED
			~TRACING
		"
		if kernel_is -lt 3 7 0; then
			linux_chkconfig_present SND_HDA_INTEL && CONFIG_CHECK+="~SND_HDA_POWER_SAVE"
			linux_chkconfig_present SND_HDA_INTEL && ERROR_KERNEL_SND_HDA_POWER_SAVE="SND_HDA_POWER_SAVE should be enabled in the kernel for full powertop function"
		fi
		ERROR_KERNEL_X86_MSR="X86_MSR is not enabled in the kernel, you almost certainly need it"
		ERROR_KERNEL_DEBUG_FS="DEBUG_FS is not enabled in the kernel, you almost certainly need it"
		ERROR_KERNEL_PERF_EVENTS="PERF_EVENTS should be enabled in the kernel for full powertop function"
		ERROR_KERNEL_TRACEPOINTS="TRACEPOINTS should be enabled in the kernel for full powertop function"
		ERROR_KERNEL_NO_HZ="NO_HZ should be enabled in the kernel for full powertop function"
		ERROR_KERNEL_HIGH_RES_TIMERS="HIGH_RES_TIMERS should be enabled in the kernel for full powertop function"
		ERROR_KERNEL_HPET_TIMER="HPET_TIMER should be enabled in the kernel for full powertop function"
		ERROR_KERNEL_CPU_FREQ_STAT="CPU_FREQ_STAT should be enabled in the kernel for full powertop function"
		ERROR_KERNEL_CPU_FREQ_GOV_ONDEMAND="CPU_FREQ_GOV_ONDEMAND should be enabled in the kernel for full powertop function"
		ERROR_KERNEL_USB_SUSPEND="USB_SUSPEND should be enabled in the kernel for full powertop function"
		ERROR_KERNEL_FTRACE="FTRACE needs to be turned on to enable BLK_DEV_IO_TRACE"
		ERROR_KERNEL_BLK_DEV_IO_TRACE="BLK_DEV_IO_TRACE needs to be turned on to enable TIMER_STATS, TRACING and EVENT_POWER_TRACING_DEPRECATED"
		ERROR_KERNEL_TIMER_STATS="TIMER_STATS should be enabled in the kernel for full powertop function"
		ERROR_KERNEL_EVENT_POWER_TRACING_DEPRECATED="EVENT_POWER_TRACING_DEPRECATED should be enabled in the kernel for full powertop function"
		ERROR_KERNEL_TRACING="TRACING should be enabled in the kernel for full powertop function"
		linux-info_pkg_setup
	else
		ewarn "unable to find kernel config, all checks disabled"
	fi
}

src_prepare() {
	if [ ${PV} == "9999" ] ; then
		eautoreconf
	fi
}

src_configure() {
	export ac_cv_search_delwin=$(usex unicode -lncursesw -lncurses)
	default
}

src_install() {
	default
	keepdir /var/cache/powertop
}
