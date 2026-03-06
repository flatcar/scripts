This directory is for Portage configuration that cannot be applied using
profiles. Files here are automatically symlinked to /etc/portage. For example,
package.mask can include repository references like `::coreos-overlay` when
placed under /etc/portage but not when part of a profile.
