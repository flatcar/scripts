We keep this package in overlay, because we need CCACHE_DIR for tool
build, so we need to modify the configure.ac script and run autoreconf
again. We also skip building doc, man and js for main build.

There wasn't too much information about the reasons for the changes.
