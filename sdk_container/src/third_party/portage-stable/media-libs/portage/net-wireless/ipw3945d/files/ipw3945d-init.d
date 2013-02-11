#!/sbin/runscript
# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/ipw3945d/files/ipw3945d-init.d,v 1.6 2007/11/01 01:59:20 uberlord Exp $

PIDFILE=/var/run/ipw3945d/ipw3945d.pid

depend() {
	before net
	need localmount
}

check() {
	# Let's check if the pidfile is still present.
	if [ -f "${PIDFILE}" ] ; then
		eerror "The pidfile ($PIDFILE) is still present."
		eerror "Please check that the daemon isn't running!"
		return 1
	fi
}

start() {
	check
	ebegin "Starting ipw3945d"
	chown ipw3945d /sys/bus/pci/drivers/ipw3945/00*/cmd
	chmod a-w,u+rw /sys/bus/pci/drivers/ipw3945/00*/cmd
	start-stop-daemon --start --exec /sbin/ipw3945d --pidfile ${PIDFILE} -- \
		--pid-file=${PIDFILE} ${ARGS}
	eend ${?}
}

stop() {
	ebegin "Stopping ipw3945d"
	start-stop-daemon --stop --exec /sbin/ipw3945d --pidfile ${PIDFILE}
	eend ${?}
}
