There are two reasons for keeping this package in coreos-overlay:

- Lower the version of the python3 dependency to 3.6.

- Drop a part of dependencies in RDEPEND that were hidden behind the
  python use flag. This normally would not be necessary, because we
  masked the use flag in our profile, but for some reason portage
  bails out when parsing RDEPEND variable with the error pasted
  below. I suppose that the solution to the problem would be updating
  either python eclasses or portage (or both).


The error from portage:

```
!!! All ebuilds that could satisfy "sys-libs/ldb" for /build/amd64-usr/ have been masked.
!!! One of the following masked packages is required to complete your request:
- sys-libs/ldb-2.3.0-r1::coreos (masked by: invalid: DEPEND: Invalid atom (Invalid use dep: ''), token 25, invalid: RDEPEND: Invalid atom (Invalid use dep: ''), token 25)
```
