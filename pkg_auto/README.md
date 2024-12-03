Scripts for package update automation
=====================================

A quick start from blank state:

- clone scripts repo and create worktrees for the old state and new state (and optionally for the branch with package automation scripts if they are not a part of the `main` branch yet):
  - `git clone https://github.com/flatcar/scripts.git scripts/main`
  - `cd scripts/main`
  - `PKG_AUTO="${PWD}/pkg_auto"`
  - `git worktree add --branch weekly-updates ../weekly-updates origin/buildbot/weekly-portage-stable-package-updates-2024-09-23`
- prepare for generating reports (create a directory, download necessary stuff, create config):
  - `mkdir ../../weekly-updates`
  - `cd ../../weekly-updates`
  - `"${PKG_AUTO}/download_sdk_and_listings.sh" -s ../../scripts/main -x aux-cleanups aux`
    - call `"${PKG_AUTO}/download_sdk_and_listings.sh" -h` to get help
  - `"${PKG_AUTO}/generate_config.sh" -a aux -n weekly-updates -o main -r reports -s ../../scripts/main -x file,wd-cleanups config`
    - call `"${PKG_AUTO}/generate_config.sh" -h` to get help
- generate the reports:
  - `"${PKG_AUTO}/generate_reports.sh" -w wd config`
  - if the command above fails, the `reports` directory (see the `-r reports` flag in the call to  `generate_config.sh` above) will have some reports that may contain hints as to why the failure happened
    - the `reports` directory may also contain files like `warnings` or `manual-work-needed`
    - the items in `warnings` file should be addressed and the report generation should be rerun, see below
    - the items in `manual-work-needed` are things to be done while processing the updates
- in order to rerun the report generation, stuff from previous run should be removed beforehand:
  - `source wd-cleanups`
  - `rm -rf reports`
  - `"${PKG_AUTO}/generate_reports.sh" -w wd config`
- if generating reports succeeded, process the updates, update the PR with the changelogs and update summaries:
  - this is the manual part, described below
- after everything is done (like the PR got merged), things needs cleaning up:
  - `source wd-cleanups`
  - `rm -rf reports`
  - `source aux-cleanups`

Processing the updates (the manual part)
========================================

The generated directory with reports will contain the `updates` directory. Within there are two files: `summary_stubs` and `changelog_stubs`. The rest of the entries are categories and packages that were updated. The first file, `summary_stubs`, contains a list of packages that have changed and TODO items associated to each package. It is mostly used for being pasted into the pull request description as an aid for the reviewers. The latter, `changelog_stubs`, can serve as a base for changelog that should be added to the `scripts` repo.

For each package in the `summary_stubs` there are TODO items. These are basically of four kinds:

- to review the changes in the ebuild
- to review the changes not in the ebuild (metadata, patch files)
- to review the occurences of the package name in the scripts repository
- to add a link to the release notes in case of a package update

It is possible that none of the changes in the package are relevant to Flatcar (like when a package got stabilized for hppa, for instance), then the package should be just dropped from the `summary_stubs`. Note that the package update is relevant, so as such should stay in the file.

The entries in `changelog_stubs` should be reviewed about relevancy (minor SDK-only packages should likely be dropped, they are seldom of interest to end-users) and the remaining entries should be updated with proper links to release notes.

There may be also entries in `manual-work-needed` which may need addressing. Most often the reason is that the new package was added, or an existing package stopped being pulled in. This would need adding an entry to the `summary_stubs`.

Another thing that to do is to check [the security reports](https://github.com/flatcar/Flatcar/issues?q=is%3Aopen+is%3Aissue+label%3Aadvisory). If the updated package brings a fix for a security issue, it should be mentioned in the summary and an entry in a separate security changelog should be added.

Other scripts
=============

There are other scripts in this directory. `inside_sdk_container.sh` is a script executed by `generate_reports.sh` inside the SDK to collect the package information. `sync_packages.sh` is a script that updates packages and saves the result to a new branch. `update_packages.sh` is `sync_packages.sh` + `generate_reports.sh`.
