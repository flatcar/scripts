#!/sbin/runscript
# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/anope/files/anope-init.d,v 1.1 2011/12/28 20:25:48 gurligebis Exp $

extra_started_commands="reload"

depend() {
	use net mysql ircd
	provide irc-services
}

start() {
	ebegin "Starting Anope IRC Services"
	start-stop-daemon --start --exec /usr/bin/services \
		--user ${ANOPE_USER} --pidfile /var/run/anope/services.pid \
		-- ${ANOPE_OPTS}
	eend $?
}

stop() {
	ebegin "Stopping Anope IRC Services"
	start-stop-daemon --stop --pidfile /var/run/anope/services.pid
	eend $?
}

reload() {
	ebegin "Reloading Anope IRC Services"
        start-stop-daemon --signal USR2 --exec /usr/bin/services \
		--pidfile /var/run/anope/services.pid
	eend $?
}

