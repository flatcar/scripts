This is a fork of dev-util/catalyst package. The reasons for having it
here are:

- Add patches that move the scripts to use python3 explicitly, because
  /usr/bin/python is still pointing to python2, but our portage is now
  a python3 code.
