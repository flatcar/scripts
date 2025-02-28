The `0001-Prevent-overflow-when-calculating-ulog-block-size.patch`
patch is for addressing CVE-2025-24528. Not sure when it can be
dropped - it currently is a part of a master branch, which is targeted
for version 1.22. So maybe when we update to 1.22 this patch can be
dropped. The krb5-1.21 branch didn't have this patch at the time of
writing (2025-02-25).

The patch was slightly modified to take into account that the patches
in this package are applied not from the top directory, but from
inside the `src` subdirectory (the S variable is modified in the
ebuild).
