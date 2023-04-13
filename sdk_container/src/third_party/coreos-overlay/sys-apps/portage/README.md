This is a fork of Gentoo's sys-apps/portage package. We make the
following changes:

- Apply some patches that weren't yet merged by upstream.

- Remove mentions of python version we haven't yet packaged.

- Disable rsync_verify USE flag to avoid pulling more dependencies.

- Overwrite the `cnf/repos.conf` file, so we do not use the gentoo
  repo.
