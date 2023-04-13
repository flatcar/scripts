# Flatcar Container Linux notes for the GCC package

This readme captures notes for upgrading GCC in the SDK toolchain.

Starting notes
- The SDK uses cross compiler environments for all boards, even "native" (x86 on x86).
- For "merely" one-shot compiling OS image packages with a newer gcc version it is sufficient to supply the build recipe and then build it as a cross compiler. For making the update persistent, the SDK needs to be build first (all 4 stages).
- The SDK build uses its own set of build recipes, i.e. **not** `src/third-party/(coreos-overlay|portage-stable). Instead, the recipes included with the bootstrap SDK (used to build the new SDK) are used. These reside in `chroot/var/gentoo/repos/gentoo`.
  - This effectively prevents *replacing* gcc in a single step, as the SDK bootstrap process will try to build the old gcc during the first stage(s)
  - Instead, the new gcc version's build recipe needs to be added, then the SDK needs to be built, and then the old version's recipe can be removed.

