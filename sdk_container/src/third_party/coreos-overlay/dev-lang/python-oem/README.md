Modifications made:

- Drop python updater and eselect python stuff (so the pkg_ functions).

- Drop src_test and the test use flag.

- Rename one patch in PATCHES variable, so I don't need to rename the
  file (the name in ebuild was using `${PN}`, which in
  `dev-lang/python` expands to `python`, whereas in
  `dev-lang/python-oem` it would expand to `python-oem`).

- Drop the following use flags and simplify the ebuild assuming that
  they were disabled: examples, gdbm, libressl, ncurses, sqlite, ssl,
  tk, wininst.

- Drop the following use flags and simplify the ebuild assuming that
  they were enabled: build, ipv6, threads.

- Drop xml use flag, but keep the internal copies of expat, do not
  disable _elementtree and pyexpat modules and tell the configure
  script to use the internal stuff.

- Keep using internal libffi, instead of depending on system-provided
  libffi.

- Move RDEPEND to DEPEND, so RDEPEND remains empty. OEM packages are
  installed after prod images are pruned of the previously installed
  package database.

- Make the following changes in configure flags:

  - Add --prefix=/usr/share/oem/python to the myeconfargs variable.

  - Change --enable-shared to --disable-shared.

  - Set --mandir, --infodir and --includedir to some subdirectory of
    /discard, so during installation this could be easily removed.

- Export some configure variables for the cross-compilation:
  ac_cv_file__dev_ptc and ac_cv_file__dev_ptmx. If not done, build
  will fail with a message saying that these should be set to either
  yes or no.

- Simplify src_install:

  - Replace the hardcoded ${ED}/usr/bin with bindir variable set to
    ${ED}/usr/share/oem/python/bin.

  - Create versionless links (python and python3) to python executable.

  - Drop sed stuff mucking with LDFLAGS.

  - Drop collision fixes.

  - Drop ABIFLAGS hack.

  - Do not install ACKS, HISTORY and NEWS files.

  - Drop gdb autoload stuff.

  - Drop pydoc.{conf,init} stuff.

  - Drop python-exec stuff.

  - Remove installed stuff in /discard.
