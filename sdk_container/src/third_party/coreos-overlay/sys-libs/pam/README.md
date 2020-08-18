This is a fork of gentoo's sys-libs/pam package. The main reasons
for having our fork seem to be:

1. We add a locked account functionality. If the account in
   `/etc/shadow` has an exclamation mark (`!`) as a first character in
   the password field, then the account is blocked.

2. We install configuration in `/usr/lib/pam`, so the configuration in
   `/etc` provided by administration can override the config we
   install.

3. For an unknown reason we drop `gen_usr_ldscript -a pam pam_misc
   pamc` from the recipe.

4. We make the `/sbin/unix_chkpwd` binary a suid one instead of
   overriding giving it a CAP_DAC_OVERRIDE to avoid a dependency loop
   between pam and libcap. The binary needs to be able to read
   /etc/shadow, so either suid or CAP_DAC_OVERRIDE capability should
   work. A suid binary is strictly less secure than capability
   override, so in long-term we would prefer to avoid having this
   hack. On the other hand - this is what we had so far.
