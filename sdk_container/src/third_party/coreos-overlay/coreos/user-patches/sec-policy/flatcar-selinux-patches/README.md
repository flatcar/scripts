The following steps were needed to make these patches:

- Clone the refpolicy repo:
  - https://github.com/SELinuxProject/refpolicy.git
- Checkout the appropriate tag:
  - For example `RELEASE_2_20231002`.
- Apply the Gentoo patch:
  - See the sec-policy/selinux-base ebuild in portage-stable for the
    patch tarball URL.
- Apply our changes:
  - `git am -p2 <OUR_PATCH>` should do the trick. Try adding `-3` flag
    in case of conflicts.
- Generate the patch:
  - Since sec-policy/selinux- packages set their source directory to
    work directory (in Gentooese: `S=${WORKDIR}/`), the user patches
    are applied from the parent directory of the refpolicy sources. In
    order to generate proper patches, do `git format-patch
    --src-prefix=a/refpolicy/ --dst-prefix=b/refpolicy/
    <SINCE_COMMIT>`
