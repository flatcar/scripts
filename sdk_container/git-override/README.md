# GIT overrides for submodules

In the SDK container, the scripts root is at a different relative path to the submodules.
The overrides in this directory are into `coreos-overlay/.git` and `portage-stable/.git` so the submodules can find their parents.

