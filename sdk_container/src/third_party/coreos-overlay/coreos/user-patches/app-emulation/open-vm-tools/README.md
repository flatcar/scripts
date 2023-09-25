The patch for configure.ac is not upstreamable at all, we either need
to modify the ebuild or the build system. We went with the latter, so
the ebuild could eventually be moved to portage-stable.

Git repo of open-vm-tools has a different layout of files than the
tarball. The files that are in toplevel directory in tarball (like
`configure.ac`) are inside the `open-vm-tools` directory in the git
repo. Which means that regenerating the user patches made in the git
repo also entails dropping the `open-vm-tools/` prefix from the paths
in the patch. The `.patch.git-orig` files are original patches from
git repo and can be useful for regenerating against a new tag.
