This overlay contains curated unmodified Gentoo packages that are part
of the CoreOS build and are exact copies of upstream Gentoo packages.

Use `src/scripts/update_ebuilds` to fetch the latest copy from Gentoo:

    cd ~/trunk/src/scripts
    repo start update-foo ../third-party/portage-stable
    ./update_ebuilds --commit app-fun/foo

Note: `update_ebuilds` can fetch from either Gentoo's anonymous CVS or
Rsync services, both of which will ban users making excessive requests.
If you have a lot of related packages to update or just aren't quite
sure what you are getting into please pull down a local copy to work
from:

    rsync -rtlv rsync://rsync.gentoo.org/gentoo-portage ~/
    ./update_ebuilds --commit --portage ~/gentoo-portage app-fun/foo

Licensing information can be found in the respective files, so consult
them directly. Most ebuilds are licensed under the GPL version 2.

Upstream Gentoo sources: http://sources.gentoo.org/gentoo-x86/
