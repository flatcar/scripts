# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/rbot/rbot-9999-r10.ebuild,v 1.9 2013/01/12 08:24:44 ulm Exp $

inherit ruby eutils user

[[ ${PV} == *"9999" ]] && inherit git-2

DESCRIPTION="rbot is a ruby IRC bot"
HOMEPAGE="http://ruby-rbot.org/"

LICENSE="|| ( feh GPL-2 )"
SLOT="0"
KEYWORDS=""
IUSE="spell aspell timezone translator shorturl nls dict figlet
	fortune cal host toilet"
ILINGUAS="zh_CN zh_TW ru nl de fr it ja"

for lang in $ILINGUAS; do
	IUSE="${IUSE} linguas_${lang}"
done

RDEPEND=">=dev-lang/ruby-1.8
	dev-ruby/ruby-bdb
	timezone? ( dev-ruby/tzinfo )
	spell? (
		aspell? ( app-text/aspell )
		!aspell? ( app-text/hunspell )
	)
	translator? ( dev-ruby/mechanize )
	shorturl? ( dev-ruby/shorturl )
	nls? ( dev-ruby/ruby-gettext )
	dict? ( dev-ruby/ruby-dict )
	figlet? ( app-misc/figlet )
	toilet? ( app-misc/toilet )
	fortune? ( games-misc/fortune-mod )
	cal? ( || ( sys-apps/util-linux sys-freebsd/freebsd-ubin ) )
	host? ( net-dns/bind-tools )"
DEPEND="
	nls? (
		dev-ruby/ruby-gettext
		dev-ruby/rake
	)"

if [[ ${PV} == *"9999" ]]; then
	SRC_URI=""
	EGIT_REPO_URI="git://ruby-rbot.org/rbot.git"
else
	MY_P="${P/_/-}"
	S="${WORKDIR}/${P%_*}"
	SRC_URI="http://ruby-rbot.org/download/${MY_P}.tgz"
fi

pkg_setup() {
	enewuser rbot -1 -1 /var/lib/rbot nobody
}

src_unpack() {
	if [[ ${PV} == *"9999" ]]; then
		git-2_src_unpack

		cd "${S}"
		sed -i -e '/\$version=/s:".\+":"'${PV}'":' bin/rbot \
			|| die "Unable to fix rbot script version."
	else
		unpack ${A}
	fi
}

src_compile() {
	disable_rbot_plugin() {
		mv "${S}"/data/rbot/plugins/$1.rb{,.disabled}
	}
	use_rbot_plugin() {
		use $1 && return
		disable_rbot_plugin "$2"
	}
	rbot_conf() {
		echo "$1: $2" >> "${T}"/rbot.conf
	}
	use_rbot_conf_path() {
		use "$1" \
			&& rbot_conf "$2" "$3" \
			|| rbot_conf "$2" /bin/false
	}

	local spell_program="/usr/bin/hunspell -i"
	if use !spell; then
		disable_rbot_plugin spell
		spell_program="/bin/false"
	elif use aspell; then
		spell_program="/usr/bin/ispell-aspell"
	fi

	rbot_conf spell.program "${spell_program}"

	if use !figlet && use !toilet; then
		disable_rbot_plugin figlet
	fi

	use_rbot_conf_path figlet figlet.path /usr/bin/figlet
	use_rbot_conf_path toilet toilet.path /usr/bin/toilet

	use_rbot_plugin timezone time
	use_rbot_plugin translator translator
	use_rbot_plugin shorturl shortenurls
	use_rbot_plugin dict dictclient

	use_rbot_plugin fortune fortune
	use_rbot_conf_path fortune fortune.path /usr/bin/fortune

	use_rbot_plugin cal cal
	use_rbot_conf_path cal cal.path /usr/bin/cal

	use_rbot_plugin host host
	use_rbot_conf_path host host.path /usr/bin/host

	local rbot_datadir="${D}"/usr/share/rbot

	# This is unfortunately pretty manual at the moment, but it's just
	# to avoid having to run special scripts to package new versions
	# of rbot. The default if new languages are added that are not
	# considered for an opt-out here is to install them, so you just
	# need to add them later.
	if use nls; then
		strip-linguas ${ILINGUAS}
		if [[ -n ${LINGUAS} ]]; then
			# As the the language name used by the rbot data files does
			# not correspond to the ISO codes we usually use for LINGUAS,
			# the following list of local varables will work as a
			# dictionary to get the name used by rbot from the ISO code.
			local lang_rbot_zh_CN="traditional_chinese"
			local lang_rbot_ru="russian"
			local lang_rbot_nl="dutch"
			local lang_rbot_de="german"
			local lang_rbot_fr="french"
			local lang_rbot_it="italian"
			local lang_rbot_ja="japanese"

			for lang in ${ILINGUAS}; do
				use linguas_${lang} && continue

				lang_varname="lang_rbot_${lang}"
				lang_rbot=${!lang_varname}

				rm -r \
					"${S}"/data/rbot/languages/${lang_rbot}.lang \
					"${S}"/data/rbot/templates/lart/larts-${lang_rbot} \
					"${S}"/data/rbot/templates/lart/praises-${lang_rbot} \
					"${S}"/data/rbot/templates/salut/salut-${lang_rbot} \
					"${S}"/po/${lang}
			done
		fi

		rake makemo || die "locale generation failed"
	fi

	ruby_econf || die "ruby_econf failed"
}

src_install() {
	${RUBY} setup.rb install --prefix="${D}" \
		|| die "setup.rb install failed"

	diropts -o rbot -g nobody -m 0700
	keepdir /var/lib/rbot

	insinto /etc
	doins "${T}"/rbot.conf

	newinitd "${FILESDIR}/rbot.init" rbot
	newconfd "${FILESDIR}/rbot.conf" rbot
}

pkg_postinst() {
	einfo
	elog "rbot now can be started as a normal service."
	elog "Check /etc/conf.d/rbot file for more information about this feature."
	einfo
}
