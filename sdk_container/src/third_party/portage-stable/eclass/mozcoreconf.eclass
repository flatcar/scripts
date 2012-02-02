# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/mozcoreconf.eclass,v 1.14 2008/01/05 16:15:09 armin76 Exp $
#
# mozcoreconf.eclass : core options for mozilla
# inherit mozconfig-2 if you need USE flags

inherit multilib flag-o-matic

RDEPEND="x11-libs/libXrender
	x11-libs/libXt
	x11-libs/libXmu
	>=sys-libs/zlib-1.1.4"

DEPEND="${RDEPEND}
	dev-util/pkgconfig"

# Set by configure (plus USE_AUTOCONF=1), but useful for NSPR
export MOZILLA_CLIENT=1
export BUILD_OPT=1
export NO_STATIC_LIB=1
export USE_PTHREADS=1

mozconfig_init() {
	declare enable_optimize pango_version myext x
	declare MOZ=$([[ ${PN} == mozilla || ${PN} == gecko-sdk ]] && echo true || echo false)
	declare FF=$([[ ${PN} == *firefox ]] && echo true || echo false)
	declare TB=$([[ ${PN} == *thunderbird ]] && echo true || echo false)
	declare SB=$([[ ${PN} == *sunbird ]] && echo true || echo false)
	declare EM=$([[ ${PN} == enigmail ]] && echo true || echo false)
	declare XUL=$([[ ${PN} == *xulrunner ]] && echo true || echo false)
	declare SM=$([[ ${PN} == seamonkey ]] && echo true || echo false)

	####################################
	#
	# Setup the initial .mozconfig
	# See http://www.mozilla.org/build/configure-build.html
	#
	####################################

	case ${PN} in
		mozilla|gecko-sdk)
			# The other builds have an initial --enable-extensions in their
			# .mozconfig.  The "default" set in configure applies to mozilla
			# specifically.
			: >.mozconfig || die "initial mozconfig creation failed"
			mozconfig_annotate "" --enable-extensions=default ;;
		*firefox)
			cp browser/config/mozconfig .mozconfig \
				|| die "cp browser/config/mozconfig failed" ;;
		enigmail)
			cp mail/config/mozconfig .mozconfig \
				|| die "cp mail/config/mozconfig failed" ;;
		*xulrunner)
			cp xulrunner/config/mozconfig .mozconfig \
				|| die "cp xulrunner/config/mozconfig failed" ;;
		*sunbird)
			cp calendar/sunbird/config/mozconfig .mozconfig \
				|| die "cp calendar/sunbird/config/mozconfig failed" ;;
		*thunderbird)
			cp mail/config/mozconfig .mozconfig \
				|| die "cp mail/config/mozconfig failed" ;;
		seamonkey)
			# The other builds have an initial --enable-extensions in their
			# .mozconfig.  The "default" set in configure applies to mozilla
			# specifically.
			: >.mozconfig || die "initial mozconfig creation failed"
			mozconfig_annotate "" --enable-application=suite
			mozconfig_annotate "" --enable-extensions=default ;;
	esac

	####################################
	#
	# CFLAGS setup and ARCH support
	#
	####################################

	# Set optimization level based on CFLAGS
	if is-flag -O0; then
		mozconfig_annotate "from CFLAGS" --enable-optimize=-O0
	elif [[ ${ARCH} == hppa ]]; then
		mozconfig_annotate "more than -O0 causes segfaults on hppa" --enable-optimize=-O0
	elif is-flag -O1; then
		mozconfig_annotate "from CFLAGS" --enable-optimize=-O1
	elif is-flag -Os; then
		mozconfig_annotate "from CFLAGS" --enable-optimize=-Os
	else
		mozconfig_annotate "mozilla fallback" --enable-optimize=-O2
	fi

	# Now strip optimization from CFLAGS so it doesn't end up in the
	# compile string
	filter-flags '-O*'

	# Strip over-aggressive CFLAGS - Mozilla supplies its own
	# fine-tuned CFLAGS and shouldn't be interfered with..  Do this
	# AFTER setting optimization above since strip-flags only allows
	# -O -O1 and -O2
	strip-flags

	# Additional ARCH support
	case "${ARCH}" in
	alpha)
		# Historically we have needed to add -fPIC manually for 64-bit.
		# Additionally, alpha should *always* build with -mieee for correct math
		# operation
		append-flags -fPIC -mieee
		;;

	amd64|ia64)
		# Historically we have needed to add this manually for 64-bit
		append-flags -fPIC
		;;

	ppc64)
		append-flags -fPIC -mminimal-toc
		;;

	ppc)
		# Fix to avoid gcc-3.3.x micompilation issues.
		if [[ $(gcc-major-version).$(gcc-minor-version) == 3.3 ]]; then
			append-flags -fno-strict-aliasing
		fi
		;;

	sparc)
		# Sparc support ...
		replace-sparc64-flags
		;;

	x86)
		if [[ $(gcc-major-version) -eq 3 ]]; then
			# gcc-3 prior to 3.2.3 doesn't work well for pentium4
			# see bug 25332
			if [[ $(gcc-minor-version) -lt 2 ||
				( $(gcc-minor-version) -eq 2 && $(gcc-micro-version) -lt 3 ) ]]
			then
				replace-flags -march=pentium4 -march=pentium3
				filter-flags -msse2
			fi
		fi
		;;
	esac

	if [[ $(gcc-major-version) -eq 3 ]]; then
		# Enable us to use flash, etc plugins compiled with gcc-2.95.3
		mozconfig_annotate "building with >=gcc-3" --enable-old-abi-compat-wrappers

		# Needed to build without warnings on gcc-3
		CXXFLAGS="${CXXFLAGS} -Wno-deprecated"
	fi

	# Go a little faster; use less RAM
	append-flags "$MAKEEDIT_FLAGS"

	####################################
	#
	# mozconfig setup
	#
	####################################

	mozconfig_annotate gentoo \
		--disable-installer \
		--disable-pedantic \
		--enable-crypto \
		--with-system-jpeg \
		--with-system-png \
		--with-system-zlib \
		--disable-updater \
		--enable-default-toolkit=gtk2 \
		--enable-pango \
		--enable-svg \
		--enable-svg-renderer=cairo \
		--enable-system-cairo \
		--disable-strip \
		--disable-strip-libs

	if [[ ${PN} != seamonkey ]]; then
		mozconfig_annotate gentoo \
			--enable-single-profile \
			--disable-profilesharing \
			--disable-profilelocking
	fi

	# Here is a strange one...
	if is-flag '-mcpu=ultrasparc*' || is-flag '-mtune=ultrasparc*'; then
		mozconfig_annotate "building on ultrasparc" --enable-js-ultrasparc
	fi
}

# Simulate the silly csh makemake script
makemake() {
	typeset m topdir
	for m in $(find . -name Makefile.in); do
		topdir=$(echo "$m" | sed -r 's:[^/]+:..:g')
		sed -e "s:@srcdir@:.:g" -e "s:@top_srcdir@:${topdir}:g" \
			< ${m} > ${m%.in} || die "sed ${m} failed"
	done
}

makemake2() {
	for m in $(find ../ -name Makefile.in); do
		topdir=$(echo "$m" | sed -r 's:[^/]+:..:g')
		sed -e "s:@srcdir@:.:g" -e "s:@top_srcdir@:${topdir}:g" \
			< ${m} > ${m%.in} || die "sed ${m} failed"
	done
}

# mozconfig_annotate: add an annotated line to .mozconfig
#
# Example:
# mozconfig_annotate "building on ultrasparc" --enable-js-ultrasparc
# => ac_add_options --enable-js-ultrasparc # building on ultrasparc
mozconfig_annotate() {
	declare reason=$1 x ; shift
	[[ $# -gt 0 ]] || die "mozconfig_annotate missing flags for ${reason}\!"
	for x in ${*}; do
		echo "ac_add_options ${x} # ${reason}" >>.mozconfig
	done
}

# mozconfig_use_enable: add a line to .mozconfig based on a USE-flag
#
# Example:
# mozconfig_use_enable truetype freetype2
# => ac_add_options --enable-freetype2 # +truetype
mozconfig_use_enable() {
	declare flag=$(use_enable "$@")
	mozconfig_annotate "$(useq $1 && echo +$1 || echo -$1)" "${flag}"
}

# mozconfig_use_with: add a line to .mozconfig based on a USE-flag
#
# Example:
# mozconfig_use_with kerberos gss-api /usr/$(get_libdir)
# => ac_add_options --with-gss-api=/usr/lib # +kerberos
mozconfig_use_with() {
	declare flag=$(use_with "$@")
	mozconfig_annotate "$(useq $1 && echo +$1 || echo -$1)" "${flag}"
}

# mozconfig_use_extension: enable or disable an extension based on a USE-flag
#
# Example:
# mozconfig_use_extension gnome gnomevfs
# => ac_add_options --enable-extensions=gnomevfs
mozconfig_use_extension() {
	declare minus=$(useq $1 || echo -)
	mozconfig_annotate "${minus:-+}$1" --enable-extensions=${minus}${2}
}

# mozconfig_final: display a table describing all configuration options paired
# with reasons, then clean up extensions list
mozconfig_final() {
	declare ac opt hash reason
	echo
	echo "=========================================================="
	echo "Building ${PF} with the following configuration"
	grep ^ac_add_options .mozconfig | while read ac opt hash reason; do
		[[ -z ${hash} || ${hash} == \# ]] \
			|| die "error reading mozconfig: ${ac} ${opt} ${hash} ${reason}"
		printf "    %-30s  %s\n" "${opt}" "${reason:-mozilla.org default}"
	done
	echo "=========================================================="
	echo

	# Resolve multiple --enable-extensions down to one
	declare exts=$(sed -n 's/^ac_add_options --enable-extensions=\([^ ]*\).*/\1/p' \
		.mozconfig | xargs)
	sed -i '/^ac_add_options --enable-extensions/d' .mozconfig
	echo "ac_add_options --enable-extensions=${exts// /,}" >> .mozconfig
}
