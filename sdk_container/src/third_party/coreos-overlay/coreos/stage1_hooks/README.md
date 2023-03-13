The scripts in this directory are called by the SDK bootstrapping
script when setting up the portage-stable and coreos-overlay repos for
the stage1 build. The scripts are invoked with two arguments - a path
to the stage1 repository, and a path to the current repository. The
difference between the two is that the stage1 repository is a copy of
a repository saved in the seed SDK (thus it's going to be an older
version of the repository), whereas the current repository is a
repository that will be a base of the new SDK. The idea here is that
something in the stage1 repository may be too old, thus it should be
replaced with its equivalent from the current repository.

For more information about the bootstrap process, please see the
`bootstrap_sdk` script in [the scripts
repository](https://github.com/flatcar/scripts).

The script for portage-stable should end with `-portage-stable.sh`,
and the script for coreos-overlay with '-coreos-overlay.sh`. For
example: `0000-replace-ROOTPATH-coreos-overlay.sh`.
