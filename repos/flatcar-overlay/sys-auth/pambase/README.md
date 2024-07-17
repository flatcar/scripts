This is a not-really-a-fork of gentoo's `sys-auth/pambase`
package. The main reasons for having it in `coreos-overlay` are:

1. The `sys-apps/baselayout` package replaced it, so this package
   became a stub.

2. The stub is needed for compatibility with gentoo packages that
   depend on pambase. When updating some package that depends on a
   greater version of pambase than this stub provides, simply bump the
   version of the the stub, so the dependency can be satisfied.
