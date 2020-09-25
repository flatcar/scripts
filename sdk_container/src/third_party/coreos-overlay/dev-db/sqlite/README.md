This is a fork of gentoo's `dev-db/sqlite` package. The main
reasons for having our fork are:

1. Even in case of sqlite >= 3.32.0, we still need to keep conditions to
   distinguish full archive from non-full archive. Main reason for that is
   because it is not possible to build sqlite from its full archive (i.e.
   "-src"), which depends `dev-lang/tcl`. Either we need to make
   `dev-lang/tcl` available in the Flatcar SDK, or we need to bring back
   the ability of dealing with its non-full archive. (i.e. "-autoconf")
   While the former is ideal way to go in the future, it will require
   additional updates in the SDK-only release. The latter is easier for
   us to resolve the on-going security issues in the short term.
