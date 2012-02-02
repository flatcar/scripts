# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/mailer.eclass,v 1.16 2009/11/30 04:19:36 abcd Exp $

# @DEAD
# To be removed on 2011/11/30.
ewarn "Please fix your package (${CATEGORY}/${PF}) to not use ${ECLASS}.eclass"

EXPORT_FUNCTIONS pkg_postrm

# Gets current mailer profile
mailer_get_current() {
	mailer-config --get-current-profile
}

# Set current mailer profile
mailer_set_profile() {
	local newprofile=${1:-${P}}

	ebegin "Setting the current mailer profile to \"${newprofile}\""
		mailer-config --set-profile ${newprofile} >/dev/null || die
	eend $?
}

# Wipe unused configs
mailer_wipe_confs() {
	local x i

	ebegin "Wiping all unused mailer profiles"
		for x in /etc/mail/*.mailer ; do
			i=${x##*/}
			i=${i%.mailer}

			[[ ${i} == ${P} ]] && continue
			[[ ${i} == "default" ]] && continue
			has_version "~mail-mta/${i}" || rm ${x}
		done
	eend 0
}

mailer_pkg_postrm() {
	if use mailwrapper ; then
		mailer_wipe_confs

		# We are removing the current profile, switch back to default
		[[ $(mailer_get_current) == ${P} ]] && mailer_set_profile default
	fi
}
