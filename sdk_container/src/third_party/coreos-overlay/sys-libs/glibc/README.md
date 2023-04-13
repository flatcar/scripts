# GLibc

The system's C library, sometimes referred to as "service pack for the C
language". The build recipe has a single modification over the one Gentoo
upstream uses: in the installation callback `glibc_do_src_install`, we remove
all of glibc's `/etc` files right after the stock glibc build diligently
installed them, since we ship our own `/etc` stuff via the `baseimage` recipe.
The addition sits at the end of the `glibc_do_src_install` function and is duly
labelled `## Flatcar Container Linux: ...`.
