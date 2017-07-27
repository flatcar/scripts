This overlay contains curated unmodified Gentoo packages that are part
of the Container Linux build and are exact copies of upstream Gentoo packages.

Use `src/scripts/update_ebuilds` to fetch the latest copy from Gentoo:

    cd ~/trunk/src/scripts
    repo start update-foo ../third-party/portage-stable
    ./update_ebuilds --commit app-fun/foo

Note: `update_ebuilds` can fetch from either Gentoo's Github mirror or
Rsync services.
If you'd prefer to use a local copy of the portage tree, you can point
`update_ebuilds` at a local filepath:

    rsync -rtlv rsync://rsync.gentoo.org/gentoo-portage ~/gentoo-portage
    ./update_ebuilds --commit --portage ~/gentoo-portage app-fun/foo

Licensing information can be found in the respective files, so consult
them directly. Most ebuilds are licensed under the GPL version 2.

Upstream Gentoo sources: http://sources.gentoo.org/gentoo-x86/
