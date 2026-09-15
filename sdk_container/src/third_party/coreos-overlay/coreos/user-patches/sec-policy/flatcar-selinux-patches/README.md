The following steps were needed to make these patches:

- Clone the refpolicy repo:
  - https://github.com/SELinuxProject/refpolicy.git
- Checkout the appropriate tag:
  - For example `RELEASE_2_20231002`.
- Apply the Gentoo patch:
  - See the sec-policy/selinux-base ebuild in the gentoo repo for the
    patch tarball URL.
- Apply our changes:
  - `git am <OUR_PATCH>` should do the trick. Try adding `-3` flag in
    case of conflicts.
- Generate the patch:
  - Just `git format-patch <SINCE_COMMIT>`
