The scripts there are called when setting up the portage-stable and
coreos-overlay repos for the stage1 build. When the scripts are
invoked, they receive a path to the repository as a parameter. The
script for portage-stable should end with `-portage-stable.sh`, and
the script for coreos-overlay with '-coreos-overlay.sh`. For example
`0000-replace-ROOTPATH-coreos-overlay.sh`.
