# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/vmware.eclass,v 1.33 2010/03/09 13:12:08 abcd Exp $

# This eclass is for all vmware-* ebuilds in the tree and should contain all
# of the common components across the multiple packages.

# Only one package per "product" is allowed to be installed at any given time.

inherit pax-utils eutils

EXPORT_FUNCTIONS pkg_preinst pkg_postinst pkg_setup src_install src_unpack pkg_postrm

DEPEND="x11-misc/shared-mime-info"

export ANY_ANY="vmware-any-any-update115"
#export TOOLS_ANY="vmware-tools-any-update1"
export VMWARE_GROUP=${VMWARE_GROUP:-vmware}
export VMWARE_INSTALL_DIR=/opt/${PN//-//}

vmware_create_initd() {
	dodir "${config_dir}"/init.d/rc{0,1,2,3,4,5,6}.d
	# This is to fix a problem where if someone merges vmware and then
	# before configuring vmware they upgrade or re-merge the vmware
	# package which would rmdir the /etc/vmware/init.d/rc?.d directories.
	keepdir "${config_dir}"/init.d/rc{0,1,2,3,4,5,6}.d
}

vmware_run_questions() {
	vmware_determine_product
	# Questions:
	einfo "Adding answers to ${config_dir}/locations"
	locations="${D}${config_dir}/locations"
	echo "answer BINDIR ${VMWARE_INSTALL_DIR}/bin" >> ${locations}
	echo "answer LIBDIR ${VMWARE_INSTALL_DIR}/lib" >> ${locations}
	echo "answer MANDIR ${VMWARE_INSTALL_DIR}/man" >> ${locations}
	echo "answer DOCDIR ${VMWARE_INSTALL_DIR}/doc" >> ${locations}
	if [ "${product}" == "vmware" -o "${product}" == "vmware-tools" ]
	then
		echo "answer SBINDIR ${VMWARE_INSTALL_DIR}/sbin" >> ${locations}
		echo "answer RUN_CONFIGURATOR no" >> ${locations}
		echo "answer INITDIR ${config_dir}/init.d" >> ${locations}
		echo "answer INITSCRIPTSDIR ${config_dir}/init.d" >> ${locations}
	fi
}

vmware_determine_product() {
	# Set the product category, and the category options
	shortname=$(echo ${PN} | cut -d- -f2-)
	case "${shortname}" in
		workstation|server|player)
			product="vmware"
			config_program="vmware-config.pl"
			;;
		server-console|esx-console|gsx-console)
			product="vmware-console"
			config_program="vmware-config-console.pl"
			;;
		workstation-tools|esx-tools|gsx-tools|server-tools)
			product="vmware-tools"
			config_program="vmware-config-tools.pl"
			;;
		*)
			product="unknown"
			;;
	esac
	config_dir="/etc/${product}"

	# Set per package options
	case "${shortname}" in
		workstation)
			FULL_NAME="Workstation"
			;;
		player)
			FULL_NAME="Player"
			;;
		server)
			FULL_NAME="Server"
			;;
		server-console)
			FULL_NAME="Server Console"
			config_program="vmware-config-server-console.pl"
			config_dir="/etc/${PN}"
			;;
		esx-console)
			FULL_NAME="ESX Console"
			;;
	esac
}

vmware_pkg_setup() {
	vmware_determine_product
}

vmware_src_unpack() {
	vmware_determine_product
	case "${product}" in
		vmware-tools)
			# We grab our tarball from "CD"
			einfo "You will need ${TARBALL} from the VMware installation."
			einfo "Select VM->Install VMware Tools from VMware's menu."
			cdrom_get_cds ${TARBALL}
			;;
	esac
	# If there is anything to unpack, at all, then we should be using MY_P.
	if [[ -n "${MY_P}" ]]
	then
		if [[ -e "${CDROM_ROOT}"/${MY_P}.tar.gz ]]
		then
			tar xzf "${CDROM_ROOT}"/${MY_P}.tar.gz || die
		else
			unpack "${MY_P}".tar.gz
		fi

		if [[ -n "${ANY_ANY}" ]]
		then
			unpack "${ANY_ANY}".tar.gz
			# Move the relevant ANY_ANY files now, so that they can be patched later...
			mv -f "${ANY_ANY}"/services.sh "${S}"/installer/services.sh
			# We should be able to get rid of this eventually,
			# since we'll be using vmware-modules in future...
			[[ "${product}" == "vmware" ]] && \
				mv -f "${ANY_ANY}"/*.tar "${S}"/lib/modules/source
			[[ -e lib/bin/vmware ]] && \
				chmod 755 lib/bin/vmware
			[[ -e bin/vmnet-bridge ]] && \
				chmod 755 bin/vmnet-bridge
			[[ -e lib/bin/vmware-vmx ]] && \
				chmod 755 lib/bin/vmware-vmx
			[[ -e lib/bin-debug/vmware-vmx ]] && \
				chmod 755 lib/bin-debug/vmware-vmx
			if [[ "${RUN_UPDATE}" == "yes" ]]
			then
				cd "${S}"/"${ANY_ANY}"
				./update vmware ../lib/bin/vmware || die
				./update bridge ../bin/vmnet-bridge || die
				./update vmx ../lib/bin/vmware-vmx || die
				./update vmxdebug ../lib/bin-debug/vmware-vmx || die
			fi
		fi

		# Remove PAX MPROTECT flag from all applicable files in /bin, /sbin for
		# the vmware package only (since modules, tools and console should not
		# need to generate code on the fly in memory).
		[[ "${product}" == "vmware" ]] && pax-mark -m \
		$(list-paxables ${S}/{bin{,-debug},sbin}/{vmware-serverd,vmware-vmx})

		# Run through any patches that might need to be applied
		cd "${S}"
		if [[ -d "${FILESDIR}/${PV}" ]]
		then
			EPATCH_SUFFIX="patch"
			epatch "${FILESDIR}"/${PV}
		fi
		if [[ -n "${PATCHES}" ]]
		then
			for patch in ${PATCHES}
			do
				epatch "${FILESDIR}"/${patch}
			done
		fi
		# Unpack our new libs
		for a in ${A}
		do
			case ${a} in
				vmware-libssl.so.0.9.7l.tar.bz2)
					unpack vmware-libssl.so.0.9.7l.tar.bz2
					;;
				vmware-libcrypto.so.0.9.7l.tar.bz2)
					unpack vmware-libcrypto.so.0.9.7l.tar.bz2
					;;
			esac
		done
	fi
}

vmware_src_install() {
	# We won't want any perl scripts from VMware once we've finally got all
	# of the configuration done, but for now, they're necessary.
	#rm -f bin/*.pl

	# As backwards as this seems, we're installing our icons first.
	if [[ -e lib/share/icons/48x48/apps/${PN}.png ]]
	then
		doicon lib/share/icons/48x48/apps/${PN}.png
	elif [[ -e doc/icon48x48.png ]]
	then
		newicon doc/icon48x48.png ${PN}.png
	elif [[ -e "${DISTDIR}/${product}.png" ]]
	then
		newicon "${DISTDIR}"/${product}.png ${PN}.png
	fi

	# Since with Gentoo we compile everthing it doesn't make sense to keep
	# the precompiled modules arround. Saves about 4 megs of disk space too.
	rm -rf "${S}"/lib/modules/binary
	# We also don't need to keep the icons around, or do we?
	#rm -rf ${S}/lib/share/icons

	# Just like any good monkey, we install the documentation and man pages.
	[[ -d doc ]] && dodoc doc/*
	if [[ -d man ]]
	then
		cd man
		for x in *
		do
			doman ${x}/* || die "doman"
		done
	fi
	cd "${S}"

	# We remove the shipped libssl for bug #148682
	if [ -d "${S}"/libssl.so.0.9.7 ]
	then
		rm -rf "${S}"/lib/lib/libssl.so.0.9.7
		# Now, we move in our own
		cp -pPR "${S}"/libssl.so.0.9.7 "${S}"/lib/lib
	fi
	# We remove the shipped libcrypto for bug #148682
	if [ -d "${S}"/libcrypto.so.0.9.7 ]
	then
		rm -rf "${S}"/lib/lib/libcrypto.so.0.9.7
		# Now, we move in our own
		cp -pPR "${S}"/libcrypto.so.0.9.7 "${S}"/lib/lib
	fi

	# We loop through our directories and copy everything to our system.
	for x in bin lib sbin
	do
		if [[ -e "${S}/${x}" ]]
		then
			dodir "${VMWARE_INSTALL_DIR}"/${x}
			cp -pPR "${S}"/${x}/* "${D}""${VMWARE_INSTALL_DIR}"/${x} \
				|| die "copying ${x}"
		fi
	done

	# If we have an /etc directory, we copy it.
	if [[ -e "${S}/etc" ]]
	then
		dodir "${config_dir}"
		cp -pPR "${S}"/etc/* "${D}""${config_dir}"
		fowners root:${VMWARE_GROUP} "${config_dir}"
		fperms 770 "${config_dir}"
	fi

	# If we have any helper files, we install them.  First, we check for an
	# init script.
	if [[ -e "${FILESDIR}/${PN}.rc" ]]
	then
		newinitd "${FILESDIR}"/${PN}.rc ${product} || die "newinitd"
	fi
	# Then we check for an environment file.
	if [[ -e "${FILESDIR}/90${PN}" ]]
	then
		doenvd "${FILESDIR}"/90${PN} || die "doenvd"
	fi
	# Last, we check for any mime files.
	if [[ -e "${FILESDIR}/${PN}.xml" ]]
	then
		insinto /usr/share/mime/packages
		doins "${FILESDIR}"/${PN}.xml || die "mimetypes"
	fi

	# Blame bug #91191 for this one.
	if [[ -e doc/EULA ]]
	then
		insinto "${VMWARE_INSTALL_DIR}"/doc
		doins doc/EULA || die "copying EULA"
	fi

	# Do we have vmware-ping/vmware-vmx?  If so, make them setuid.
	for p in /bin/vmware-ping /lib/bin/vmware-vmx /lib/bin-debug/vmware-vmx /lib/bin/vmware-vmx-debug /sbin/vmware-authd;
	do
		if [ -x "${D}${VMWARE_INSTALL_DIR}${p}" ]
		then
			fowners root:${VMWARE_GROUP} "${VMWARE_INSTALL_DIR}"${p}
			fperms 4750 "${VMWARE_INSTALL_DIR}"${p}
		fi
	done

	# This removed the user/group warnings
	# But also broke vmware-server with FEATURES="userpriv" since it removes
	# the set-UID bit
	#chown -R root:${VMWARE_GROUP} ${D} || die

	# We like desktop icons.
	# TODO: Fix up the icon creation, across the board.
	#make_desktop_entry ${PN} "VMware ${FULL_NAME}"

	# We like symlinks for console users.
	# TODO: Fix up the symlink creation, across the board.
	# dosym ${VMWARE_INSTALL_DIR}/bin/${PN} /usr/bin/${PN}

	# TODO: Replace this junk
	# Everything after this point will hopefully go away once we can rid
	# ourselves of the evil perl configuration scripts.

	if [ "${product}" == "vmware" -o "${product}" == "vmware-tools" ]
	then

		# We have to create a bunch of rc directories for the init script
		vmware_create_initd || die "creating rc directories"

		# Now, we copy in our services.sh file
		exeinto "${config_dir}"/init.d
		newexe installer/services.sh ${product} || die "services.sh"

		# Set the name
		dosed "s:%LONGNAME%:Vmware ${FULL_NAME}:" \
			"${config_dir}"/init.d/${product}
		[ "${shortname}" == "server" ] && dosed "s:%SHORTNAME%:wgs:" \
			"${config_dir}"/init.d/${product}
	fi

	# Finally, we run the "questions"
	vmware_run_questions || die "running questions"
}

vmware_pkg_preinst() {
	# This is run here due to bug #143150
	[ -z "${product}" ] && vmware_determine_product

	# This must be done after the install to get the mtimes on each file
	# right.

	#Note: it's a bit weird to use ${D} in a preinst script but it should work
	#(drobbins, 1 Feb 2002)

	einfo "Generating ${config_dir}/locations file."
	d=`echo ${D} | wc -c`
	for x in `find ${D}${VMWARE_INSTALL_DIR} ${D}${config_dir}` ; do
		x="`echo ${x} | cut -c ${d}-`"
		if [ -d "${D}/${x}" ] ; then
			echo "directory ${x}" >> "${D}${config_dir}"/locations
		else
			echo -n "file ${x}" >> "${D}${config_dir}"/locations
			if [ "${x}" == "${config_dir}/locations" ] ; then
				echo "" >> "${D}${config_dir}"/locations
			elif [ "${x}" == "${config_dir}/not_configured" ] ; then
				echo "" >> "${D}${config_dir}"/locations
			else
				echo -n " " >> "${D}${config_dir}"/locations
				find ${D}${x} -printf %T@ >> "${D}${config_dir}"/locations
				echo "" >> "${D}${config_dir}"/locations
			fi
		fi
	done
}

vmware_pkg_postinst() {
	update-mime-database /usr/share/mime
	[[ -d "${config_dir}" ]] && chown -R root:${VMWARE_GROUP} ${config_dir}

	# This is to fix the problem where the not_configured file doesn't get
	# removed when the configuration is run. This doesn't remove the file
	# It just tells the vmware-config.pl script it can delete it.
	einfo "Updating ${config_dir}/locations"
	for x in "${config_dir}"/._cfg????_locations ; do
		if [ -f $x ] ; then
			cat $x >> "${config_dir}"/locations
			rm $x
		fi
	done

	echo
	elog "You need to run "
	elog "    ${VMWARE_INSTALL_DIR}/bin/${config_program}"
	elog "to complete the install."
	echo
	einfo "For VMware Add-Ons just visit"
	einfo "http://www.vmware.com/download/downloadaddons.html"
	echo
	if [ "${PN}" == "vmware-player" ]
	then
		elog "After configuring, run vmplayer to launch"
	else
		elog "After configuring, run ${PN} to launch"
	fi
	echo
	if [ "${product}" == "vmware" -o "${product}" == "vmware-tools" ]
	then
		elog "Also note that when you reboot you should run:"
		elog "    /etc/init.d/${product} start"
		elog "before trying to run ${product}.  Or you could just add it to"
		elog "the default runlevel:"
		elog "    rc-update add ${product} default"
		echo
		ewarn "VMWare allows for the potential of overwriting files as root.  Only"
		ewarn "give VMWare access to trusted individuals."
		echo
	fi
	ewarn "Remember, in order to run VMware ${FULL_NAME}, you have to"
	ewarn "be in the '${VMWARE_GROUP}' group."
	echo
}

vmware_pkg_postrm() {
	[ -z "${product}" ] && vmware_determine_product
	local product_extras
	if [ "${product}" == "vmware" ]
	then
		product_extras=" and /etc/init.d/${product}"
	fi
	if ! has_version app-emulation/${PN}; then
		echo
		elog "To remove all traces of ${product} you will need to remove the files"
		elog "in ${config_dir}${product_extras}."
		elog "If the vmware-modules package is installed, you may no longer need it."
		echo
	fi
}
