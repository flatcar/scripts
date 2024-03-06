This is a straight copy of Gentoo package, with no modifications at
all. The reason for keeping it in overlay is that upstream plans to
drop the package on 28th March, 2024.

The package is needed only by the app-emulation/google-compute-engine
package, which is quite old (version string mentions 2019), so work
needs to be done to update it in order to drop the dependency on the
obsolete boto package (Gentoo has dev-python/boto3 package).
