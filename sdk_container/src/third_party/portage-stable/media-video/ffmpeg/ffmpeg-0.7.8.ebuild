# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/ffmpeg/ffmpeg-0.7.8.ebuild,v 1.7 2011/12/18 22:11:07 halcy0n Exp $

EAPI="2"

SCM=""
if [ "${PV#9999}" != "${PV}" ] ; then
	SCM="git-2"
	EGIT_REPO_URI="git://git.videolan.org/ffmpeg.git"
fi

inherit eutils flag-o-matic multilib toolchain-funcs ${SCM}

DESCRIPTION="Complete solution to record, convert and stream audio and video. Includes libavcodec."
HOMEPAGE="http://ffmpeg.org/"
if [ "${PV#9999}" != "${PV}" ] ; then
	SRC_URI=""
elif [ "${PV%_p*}" != "${PV}" ] ; then # Snapshot
	SRC_URI="mirror://gentoo/${P}.tar.bz2"
else # Release
	SRC_URI="http://ffmpeg.org/releases/${P/_/-}.tar.bz2"
fi
FFMPEG_REVISION="${PV#*_p}"

LICENSE="GPL-2 amr? ( GPL-3 ) encode? ( aac? ( GPL-3 ) )"
SLOT="0"
if [ "${PV#9999}" = "${PV}" ] ; then
	KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd"
fi
IUSE="
	+3dnow +3dnowext aac alsa altivec amr avx bindist +bzip2 celt cpudetection
	custom-cflags debug dirac doc +encode faac frei0r gsm +hardcoded-tables
	ieee1394 jack jpeg2k +mmx +mmxext mp3 network oss pic +qt-faststart rtmp
	schroedinger sdl speex +ssse3 static-libs test theora threads truetype
	v4l vaapi vdpau vorbis vpx X x264 xvid +zlib
	"

VIDEO_CARDS="nvidia"

for x in ${VIDEO_CARDS}; do
	IUSE="${IUSE} video_cards_${x}"
done

RDEPEND="
	alsa? ( media-libs/alsa-lib )
	amr? ( media-libs/opencore-amr )
	bzip2? ( app-arch/bzip2 )
	celt? ( >=media-libs/celt-0.11.1 )
	dirac? ( media-video/dirac )
	encode? (
		aac? ( media-libs/vo-aacenc )
		amr? ( media-libs/vo-amrwbenc )
		faac? ( media-libs/faac )
		mp3? ( >=media-sound/lame-3.98.3 )
		theora? ( >=media-libs/libtheora-1.1.1[encode] media-libs/libogg )
		vorbis? ( media-libs/libvorbis media-libs/libogg )
		x264? ( >=media-libs/x264-0.0.20110426 )
		xvid? ( >=media-libs/xvid-1.1.0 )
	)
	frei0r? ( media-plugins/frei0r-plugins )
	gsm? ( >=media-sound/gsm-1.0.12-r1 )
	ieee1394? ( media-libs/libdc1394 sys-libs/libraw1394 )
	jack? ( media-sound/jack-audio-connection-kit )
	jpeg2k? ( >=media-libs/openjpeg-1.3-r2 )
	rtmp? ( >=media-video/rtmpdump-2.2f )
	sdl? ( >=media-libs/libsdl-1.2.13-r1[audio,video] )
	schroedinger? ( media-libs/schroedinger )
	speex? ( >=media-libs/speex-1.2_beta3 )
	truetype? ( media-libs/freetype:2 )
	vaapi? ( >=x11-libs/libva-0.32 )
	video_cards_nvidia? ( vdpau? ( x11-libs/libvdpau ) )
	vpx? ( >=media-libs/libvpx-0.9.6 )
	X? ( x11-libs/libX11 x11-libs/libXext )
	zlib? ( sys-libs/zlib )
	!media-video/qt-faststart
"

DEPEND="${RDEPEND}
	>=sys-devel/make-3.81
	dirac? ( dev-util/pkgconfig )
	doc? ( app-text/texi2html )
	ieee1394? ( dev-util/pkgconfig )
	mmx? ( dev-lang/yasm )
	rtmp? ( dev-util/pkgconfig )
	schroedinger? ( dev-util/pkgconfig )
	test? ( net-misc/wget )
	truetype? ( dev-util/pkgconfig )
	v4l? ( sys-kernel/linux-headers )
"

S=${WORKDIR}/${P/_/-}

src_prepare() {
	if [ "${PV%_p*}" != "${PV}" ] ; then # Snapshot
		export revision=git-N-${FFMPEG_REVISION}
	fi
	epatch "${FILESDIR}"/${PN}-0.7.6-fix_ppc64_32ul.patch #387207
}

src_configure() {
	local myconf="${EXTRA_FFMPEG_CONF}"
	# Set to --enable-version3 if (L)GPL-3 is required
	local version3=""

	# enabled by default
	for i in debug doc network vaapi zlib; do
		use ${i} || myconf="${myconf} --disable-${i}"
	done
	use bzip2 || myconf="${myconf} --disable-bzlib"
	use sdl || myconf="${myconf} --disable-ffplay"

	use custom-cflags && myconf="${myconf} --disable-optimizations"
	use cpudetection && myconf="${myconf} --enable-runtime-cpudetect"

	#for i in h264_vdpau mpeg1_vdpau mpeg_vdpau vc1_vdpau wmv3_vdpau; do
	#	use video_cards_nvidia || myconf="${myconf} --disable-decoder=${i}"
	#	use vdpau || myconf="${myconf} --disable-decoder=${i}"
	#done
	use video_cards_nvidia && use vdpau || myconf="${myconf} --disable-vdpau"

	# Encoders
	if use encode
	then
		use mp3 && myconf="${myconf} --enable-libmp3lame"
		use aac && { myconf="${myconf} --enable-libvo-aacenc" ; version3=" --enable-version3" ; }
		use amr && { myconf="${myconf} --enable-libvo-amrwbenc" ; version3=" --enable-version3" ; }
		for i in theora vorbis x264 xvid; do
			use ${i} && myconf="${myconf} --enable-lib${i}"
		done
		if use bindist
		then
			use faac && ewarn "faac is nonfree and cannot be distributed;
			disabling faac support."
		else
			use faac && myconf="${myconf} --enable-libfaac --enable-nonfree"
		fi
	else
		myconf="${myconf} --disable-encoders"
	fi

	# libavdevice options
	use ieee1394 && myconf="${myconf} --enable-libdc1394"
	# Indevs
	# v4l1 gone since linux-headers-2.6.38
	myconf="${myconf} --disable-indev=v4l"
	use v4l || myconf="${myconf} --disable-indev=v4l2"
	for i in alsa oss jack ; do
		use ${i} || myconf="${myconf} --disable-indev=${i}"
	done
	use X && myconf="${myconf} --enable-x11grab"
	# Outdevs
	for i in alsa oss ; do
		use ${i} || myconf="${myconf} --disable-outdev=${i}"
	done
	# libavfilter options
	use frei0r && myconf="${myconf} --enable-frei0r"
	use truetype && myconf="${myconf} --enable-libfreetype"

	# Threads; we only support pthread for now but ffmpeg supports more
	use threads && myconf="${myconf} --enable-pthreads"

	# Decoders
	use amr && { myconf="${myconf} --enable-libopencore-amrwb --enable-libopencore-amrnb" ; version3=" --enable-version3" ; }
	for i in celt gsm dirac rtmp schroedinger speex vpx; do
		use ${i} && myconf="${myconf} --enable-lib${i}"
	done
	use jpeg2k && myconf="${myconf} --enable-libopenjpeg"

	# CPU features
	for i in mmx ssse3 altivec avx ; do
		use ${i} || myconf="${myconf} --disable-${i}"
	done
	use mmxext || myconf="${myconf} --disable-mmx2"
	use 3dnow || myconf="${myconf} --disable-amd3dnow"
	use 3dnowext || myconf="${myconf} --disable-amd3dnowext"
	# disable mmx accelerated code if PIC is required
	# as the provided asm decidedly is not PIC for x86.
	if use pic && use x86 ; then
		myconf="${myconf} --disable-mmx --disable-mmx2"
	fi

	# Option to force building pic
	use pic && myconf="${myconf} --enable-pic"

	# Try to get cpu type based on CFLAGS.
	# Bug #172723
	# We need to do this so that features of that CPU will be better used
	# If they contain an unknown CPU it will not hurt since ffmpeg's configure
	# will just ignore it.
	for i in $(get-flag march) $(get-flag mcpu) $(get-flag mtune) ; do
		[ "${i}" = "native" ] && i="host" # bug #273421
		[[ ${i} = *-sse3 ]] && i="${i%-sse3}" # bug 283968
		myconf="${myconf} --cpu=${i}"
		break
	done

	# Mandatory configuration
	myconf="
		--enable-gpl
		${version3}
		--enable-postproc
		--enable-avfilter
		--disable-stripping
		${myconf}"

	# cross compile support
	if tc-is-cross-compiler ; then
		myconf="${myconf} --enable-cross-compile --arch=$(tc-arch-kernel) --cross-prefix=${CHOST}-"
		case ${CHOST} in
			*freebsd*)
				myconf="${myconf} --target-os=freebsd"
				;;
			mingw32*)
				myconf="${myconf} --target-os=mingw32"
				;;
			*linux*)
				myconf="${myconf} --target-os=linux"
				;;
		esac
	fi

	# Misc stuff
	use hardcoded-tables && myconf="${myconf} --enable-hardcoded-tables"

	# Specific workarounds for too-few-registers arch...
	if [[ $(tc-arch) == "x86" ]]; then
		filter-flags -fforce-addr -momit-leaf-frame-pointer
		append-flags -fomit-frame-pointer
		is-flag -O? || append-flags -O2
		if (use debug); then
			# no need to warn about debug if not using debug flag
			ewarn ""
			ewarn "Debug information will be almost useless as the frame pointer is omitted."
			ewarn "This makes debugging harder, so crashes that has no fixed behavior are"
			ewarn "difficult to fix. Please have that in mind."
			ewarn ""
		fi
	fi

	cd "${S}"
	./configure \
		--prefix=/usr \
		--libdir=/usr/$(get_libdir) \
		--shlibdir=/usr/$(get_libdir) \
		--mandir=/usr/share/man \
		--enable-shared \
		--cc="$(tc-getCC)" \
		$(use_enable static-libs static) \
		${myconf} || die
}

src_compile() {
	emake version.h || die #252269
	emake || die

	if use qt-faststart; then
		tc-export CC
		emake -C tools qt-faststart || die
	fi
}

src_install() {
	emake DESTDIR="${D}" install install-man || die

	dodoc README INSTALL
	dodoc doc/*

	if use qt-faststart; then
		dobin tools/qt-faststart || die
	fi
}

src_test() {
	if use encode ; then
		LD_LIBRARY_PATH="${S}/libpostproc:${S}/libswscale:${S}/libavcodec:${S}/libavdevice:${S}/libavfilter:${S}/libavformat:${S}/libavutil" \
			emake test || die "Some tests failed"
	else
		ewarn "Tests fail without USE=encode, skipping"
	fi
}
