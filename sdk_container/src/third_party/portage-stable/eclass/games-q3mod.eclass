# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/games-q3mod.eclass,v 1.36 2007/03/07 15:23:39 wolf31o2 Exp $

inherit games

EXPORT_FUNCTIONS src_install pkg_postinst

DESCRIPTION="Quake III - ${MOD_DESC}"

SLOT="0"
KEYWORDS="-* amd64 ~ppc x86"
IUSE="dedicated"

DEPEND="app-arch/unzip"
RDEPEND="|| ( games-fps/quake3 games-fps/quake3-bin )
	amd64? ( app-emulation/emul-linux-x86-baselibs )
	dedicated? ( app-misc/screen )"

S=${WORKDIR}

games-q3mod_src_install() {
	[[ -z ${MOD_NAME} ]] && die "what is the name of this q3mod ?"

	local bdir=${GAMES_PREFIX_OPT}/quake3
	local mdir=${bdir}/${MOD_NAME}
	MOD_BINS=${MOD_BINS:-${MOD_NAME}}

	if [[ -d ${MOD_NAME} ]] ; then
		dodir "${bdir}"
		mv ${MOD_NAME} "${D}/${bdir}/"
	fi
	if [[ -d baseq3 ]] ; then
		dodir "${bdir}"
		mv baseq3 "${D}/${bdir}/"
	fi
	if [[ ! -z $(ls "${S}"/* 2> /dev/null) ]] ; then
		dodir "${mdir}"
		mv "${S}"/* "${D}/${mdir}/"
	fi

	if use dedicated; then
		games-q3mod_make_q3ded_exec
		newgamesbin "${T}"/q3${MOD_NAME}-ded.bin q3${MOD_BINS}-ded
	fi
	games-q3mod_make_quake3_exec
	newgamesbin "${T}"/quake3-${MOD_NAME}.bin quake3-${MOD_BINS}

	if use dedicated; then
		games-q3mod_make_init.d
		newinitd "${T}"/q3${MOD_NAME}-ded.init.d q3${MOD_BINS}-ded
		games-q3mod_make_conf.d
		newconfd "${T}"/q3${MOD_NAME}-ded.conf.d q3${MOD_BINS}-ded
	fi

	dodir "${GAMES_SYSCONFDIR}"/quake3

	dodir "${bdir}"/q3a-homedir
	dosym "${bdir}"/q3a-homedir "${GAMES_PREFIX}"/.q3a
	keepdir "${bdir}"/q3a-homedir
	prepgamesdirs
	chmod g+rw "${D}/${mdir}" "${D}/${bdir}"/q3a-homedir
	chmod -R g+rw "${D}/${GAMES_SYSCONFDIR}"/quake3
}

games-q3mod_pkg_postinst() {
	local samplecfg=${FILESDIR}/server.cfg
	local realcfg=${GAMES_PREFIX_OPT}/quake3/${MOD_NAME}/server.cfg
	if [[ -e ${samplecfg} ]] && [[ ! -e ${realcfg} ]] ; then
		cp "${samplecfg}" "${realcfg}"
	fi

	einfo "To play this mod:             quake3-${MOD_BINS}"
	use dedicated && \
	einfo "To launch a dedicated server: q3${MOD_BINS}-ded" && \
	einfo "To launch server at startup:  /etc/init.d/q3${MOD_NAME}-ded"

	games_pkg_postinst
}

games-q3mod_make_q3ded_exec() {
cat << EOF > "${T}"/q3${MOD_NAME}-ded.bin
#!/bin/sh
exec "${GAMES_BINDIR}"/q3ded-bin +set fs_game ${MOD_NAME} +set dedicated 1 +exec server.cfg \${@}
EOF
}

games-q3mod_make_quake3_exec() {
cat << EOF > "${T}"/quake3-${MOD_NAME}.bin
#!/bin/sh
exec "${GAMES_BINDIR}"/quake3-bin +set fs_game ${MOD_NAME} \${@}
EOF
}

games-q3mod_make_init.d() {
cat << EOF > "${T}"/q3${MOD_NAME}-ded.init.d
#!/sbin/runscript
$(<"${PORTDIR}"/header.txt)

depend() {
	need net
}

start() {
	ebegin "Starting ${MOD_NAME} dedicated"
	screen -A -m -d -S q3${MOD_BINS}-ded su - ${GAMES_USER_DED} -c "${GAMES_BINDIR}/q3${MOD_BINS}-ded \${${MOD_NAME}_OPTS}"
	eend \$?
}

stop() {
	ebegin "Stopping ${MOD_NAME} dedicated"
	local pid=\`screen -list | grep q3${MOD_BINS}-ded | awk -F . '{print \$1}' | sed -e s/.//\`
	if [[ -z "\${pid}" ]] ; then
		eend 1 "Lost screen session"
	else
		pid=\`pstree -p \${pid} | sed -e 's:^.*q3ded::'\`
		pid=\${pid:1:\${#pid}-2}
		if [[ -z "\${pid}" ]] ; then
			eend 1 "Lost q3ded session"
		else
			kill \${pid}
			eend \$? "Could not kill q3ded"
		fi
	fi
}

status() {
	screen -list | grep q3${MOD_BINS}-ded
}
EOF
}

games-q3mod_make_conf.d() {
	if [[ -e ${FILESDIR}/${MOD_NAME}.conf.d ]] ; then
		cp "${FILESDIR}"/${MOD_NAME}.conf.d "${T}"/q3${MOD_NAME}-ded.conf.d
		return 0
	fi
cat << EOF > "${T}"/q3${MOD_NAME}-ded.conf.d
$(<"${PORTDIR}"/header.txt)

# Any extra options you want to pass to the dedicated server
${MOD_NAME}_OPTS="+set vm_game 0 +set sv_pure 1 +set bot_enable 0 +set com_hunkmegs 64 +set net_port 27960"
EOF
}
