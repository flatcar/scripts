# Flatcar automated patch ingestion

* status: proposal
* next step: discussion, changes / updates, collect approvals
* final destination: `docs/flatcar-automated-patch-ingestion.md`

The document discusses automatically ingesting package updates and patches via the Gentoo submodule.
Packages in coreos-overlay are out of scope.

## Ingesting Updates

Flatcar uses Gentoo in a git submodule in [`sdk_container/src/third_party/gentoo`](../sdk_container/src/third_party/gentoo).
The submodule tracks Gentoo's master branch (via an [intermediate mirror](https://github.com/flatcar-hub/gentoo/tree/master) under Flatcar control, for robustness reasons).
Updates / upgrades that arrived in Gentoo can be ingested simply by rebasing the Gentoo git submodule to latest `master`.

The update ingestion and patching document covers two distinct areas:
1. **The `main` branch.**
   This branch receives updates to latest+greatest for all its packages, i.e. the latest package release marked `stable` in Gentoo will be ingested.
2. **Release branches.**
   Release branches receive patch-level updates for all packages the release includes.
   Major and minor versions of all packages in release branches will be frozen when the branch is created from `main`, i.e. at the time of the Alpha release.

## Automated Updates for the `main` Branch

Main ingests new package versions from Gentoo in a daily cadence and can be triggered manually on demand (e.g. to fix emergent critical CVEs outside the daily rhythm).
Details on ingesting these updates are outlined in "Ingestion Workflow".
* Main always gets latest+greatest.
* If desired, package unmasks can be added to the Flatcar profile to allow-list package versions deemed unstable in Gentoo.
  This is handy for helping to stabilise packages we maintain - or plan to maintain - upstream, e.g. docker/containerd/runc.
* In exceptional cases, version can be freezed by temporarily moving packages from Gentoo to coreos-overlay.
  This should be rare and well justified (e.g. SELinux profiles).

This allows for an "upstream first" development flow in which we upgrade packages and fix issues directly in upstream Gentoo.

## Automated Patching of Release Branches

Release branches ingest patch level updates of all packages on a daily cadence, using the same workflows and mechanisms as `main`.
This is implemented by "freezing" all package major and minor versions when a new Alpha branch is created.
The freeze is implemented via package masks generated at branch creation time. Masks cover major.minor package versions, but not patch level.

As a result, the Gentoo git submodule can automatically be rebased in release branches as outlined in "Ingestion Workflow" while ensuring only patch level updates will be ingested.

If a package major.minor version is discontinued by Gentoo upstream, Flatcar distro maintainers need to make a qualified decision:
1. Move the latest available patch level version before discontinuation to coreos-overlay.
   The maintenance branch will then carry that version in coreos-overlay for the lifetime of this respective major release.
2. Ship a minor (or major) version upgrade of the affected package with the next OS patch-level release.
   This may be more desirable than 1. if the package upgrade
   1. is considered low impact, e.g. shipping a new major VIM version.
   2. ships important security fixes not available for older releases.


## Ingestion Workflow

The ingestion workflow is:
1. Rebase to latest Gentoo upstream in our Gentoo mirror clone via https://github.com/flatcar-hub/gentoo/actions/workflows/auto-update.yaml.
2. Create a new branch and update the Gentoo git submodule to latest mirror `master`.
3. create a PR in the `scripts` repo using that branch.
4. run an OS image build and qemu tests for both AMD64 and ARM64.
   Test results will be posted to the PR.
5. create a package version diff between
   1. the current build and the latest nightly
   2. the current build and the latest release of the target release branch (or the latest Alpha release for `main`)
   and add it to the PR.
6. create an OS filesystem contents diff
   1. the current build and the latest nightly
   2. the current build and the latest release of the target release branch (or the latest Alpha release for `main`)
   and add it to the PR.
7. The PR is approved and merged by a maintainer based on the information provided in the PR.
   1. If build or tests failed, the PR will remain open and automation will re-use the same PR for updated builds.

Follow-up: The package version diffs generated in 5. may be used as a base for generating release changelog information.
However, this is out of scope of this document.
