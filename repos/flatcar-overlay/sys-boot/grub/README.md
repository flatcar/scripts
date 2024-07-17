Flatcar uses a patched version of the GRUB, which implements the functionality to
read the [Flatcar Container Linux partition table](https://www.flatcar.org/docs/latest/reference/developer-guides/sdk-disk-partitions/#partition-table)

## History

CoreOS Container Linux maintained a fork of the [grub](https://github.com/coreos/grub) and then was referenced
in the coreos-overlay. Any changes were made through [PRs](https://github.com/coreos/grub/pulls?q=is%3Apr+is%3Aclosed) to the grub repository.

When Flatcar was born, a `grub` repo under the flatcar-linux org was created
and referenced in the Flatcar's coreos-overlay. Except for a few, now many changes
where brought into the system.

The repo was maintained at 2.02 version. During the 2.06 migration, the philosophy
to use a separate repo was scraped, and a single patch file was created. The patch
files migrated only the essential commits, and dropped all the other commits, which
were either half-baked, or redundant at the point of migration. The two patches are applied
on top of the grub sources, and emerge is done.

Given below are the list of commits that were referenced to create the two patches.

## Summary of the patches

The patch starts with adding a new implementation of reading the GPT instead
of using the traditional module. It provides essential functionality to interact
with GPT structures on disk, and checking/validating data integrity & GPT specification.

The commits goes on to add the following modules gptprio, gptrepair, and search
commands by label and partition.

The `gptprio` command which provides a mechanism to prioritize and select the
next bootable partition based on the GPT attributes and results in flexible
partition booting. The `gptrepair` command implements the repair functions for
GPT information on a specified device. Few other functions include searching
devices by partition label or partition UUID.

## Commits

Below are the commits that are picked to create the two patches for the grub. One is
descriptive, and other is comprehensive.

<details>
  <summary>(click to expand) The descriptive log for all the commits picked </summary>

```
commit f69a9e0fdcf63ac33906e2753e14152bab2fcd05
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Sun Sep 28 21:26:21 2014 -0700

    gpt: start new GPT module

    This module is a new implementation for reading GUID Partition Tables
    which is much stricter than the existing part_gpt module and exports GPT
    data directly instead of the generic grub_partition structure. It will
    be the basis for modules that need to read/write/update GPT data.

    The current code does nothing more than read and verify the table.

commit c26743a145c918958b862d580c4261735d1c1a6e
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Sat Oct 18 15:39:13 2014 -0700

    gpt: rename misnamed header location fields

    The header location fields refer to 'this header' and 'alternate header'
    respectively, not 'primary header' and 'backup header'. The previous
    field names are backwards for the backup header.

commit 94f04a532d2b0e2b81e47a92488ebb1613bda1a0
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Sat Oct 18 16:46:17 2014 -0700

    gpt: record size of of the entries table

    The size of the entries table will be needed later when writing it back
    to disk. Restructure the entries reading code to flow a little better.

commit 3d066264ac13198e45dc151b863a9aac4c095225
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Sat Oct 18 18:18:17 2014 -0700

    gpt: consolidate crc32 computation code

    The gcrypt API is overly verbose, wrap it up in a helper function to
    keep this rather common operation easy to use.

commit dab6fac705bdad7e6ec130b24085189bcb15a5c9
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Sat Oct 18 18:21:07 2014 -0700

    gpt: add new repair function to sync up primary and backup tables.

commit 5e1829d4141343617b5e13e84298d118eac15bdf
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Sun Oct 19 14:21:29 2014 -0700

    gpt: add write function and gptrepair command

    The first hint of something practical, a command that can restore any of
    the GPT structures from the alternate location. New test case must run
    under QEMU because the loopback device used by the other unit tests does
    not support writing.

commit 2cd009dffe98c19672394608661767e4c3c84764
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Thu Oct 30 20:55:21 2014 -0700

    gpt: add a new generic GUID type

    In order to do anything with partition GUIDs they need to be stored in a
    proper structure like the partition type GUIDs. Additionally add an
    initializer macro to simplify defining both GUID types.

commit 508b02fc8a1fe58413ec8938ed1a7b149b5855fe
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Mon Nov 3 17:14:37 2014 -0800

    gpt: new gptprio.next command for selecting priority based partitions

    Basic usage would look something like this:

        gptprio.next -d usr_dev -u usr_uuid
        linuxefi ($usr_dev)/boot/vmlinuz mount.usr=PARTUUID=$usr_uuid

    After booting the system should set the 'successful' bit on the
    partition that was used.

commit f8f6f790aa7448a35c2e3aae2d1a35d9d323a1b2
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Sat Nov 15 13:27:13 2014 -0800

    gpt: split out checksum recomputation

    For basic data modifications the full repair function is overkill.

commit d9bdbc10485a5c6f610569077631294683da4e34
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Thu Nov 27 12:55:53 2014 -0800

    gpt: move gpt guid printing function to common library

commit ffb13159f1e88d8c66954c3dfbeb027f943b3b1d
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Thu Nov 27 14:54:27 2014 -0800

    gpt: switch partition names to a 16 bit type

    In UEFI/GPT strings are UTF-16 so use a uint16 to make dealing with the
    string practical.

commit febf4666fbabc3ab4eaab32f4972b45b5c64c06d
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Thu Nov 27 15:49:57 2014 -0800

    tests: add some partitions to the gpt unit test data

commit 67475f53e0ac4a844f793296ba2e4af707d5b20e
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Thu Nov 27 16:34:21 2014 -0800

    gpt: add search by partition label and uuid commands

    Builds on the existing filesystem search code. Only for GPT right now.

commit d1270a2ba31cc3dd747d410a907f272ff03a6d68
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Fri Jul 31 15:03:11 2015 -0700

    gpt: clean up little-endian crc32 computation

     - Remove problematic cast from *uint8_t to *uint32_t (alignment issue).
     - Remove dynamic allocation and associated error handling paths.
     - Match parameter ordering to existing grub_crypto_hash function.

commit bacbed2c07f4b4e21c70310814a75fa9a1c3a155
Author: Alex Crawford <alex.crawford@coreos.com>
Date:   Mon Aug 31 15:23:39 2015 -0700

    gpt: minor cleanup

commit 1545295ad49d2aff2b75c6c0e7db58214351768e
Author: Alex Crawford <alex.crawford@coreos.com>
Date:   Mon Aug 31 15:15:48 2015 -0700

    gpt: add search by disk uuid command

commit 6d4ea47541db4e0a1eab81de8843a491973e6b40
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Mon Jul 25 14:59:29 2016 -0700

    gpt: do not use disk sizes GRUB will reject as invalid later on

    GRUB assumes that no disk is ever larger than 1EiB and rejects
    reads/writes to such locations. Unfortunately this is not conveyed in
    the usual way with the special GRUB_DISK_SIZE_UNKNOWN value.

commit 99959fa2fb8bfafadc1fa5aec773a8d605a1df4e
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Wed Aug 10 18:26:03 2016 -0700

    gpt: add verbose debug logging

commit f6b89ec3156a549999a13b3d15e9a67b4a9bf824
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Wed Aug 10 18:26:03 2016 -0700

    gpt: improve validation of GPT headers

    Adds basic validation of all the disk locations in the headers, reducing
    the chance of corrupting weird locations on disk.

commit fa18d3a292bdcd61012d549c61e25d557481a05e
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Thu Aug 11 15:02:21 2016 -0700

    gpt: refuse to write to sector 0

commit b1ef48849c8dc12756793567520dfd3654539a27
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Sat Aug 20 17:42:12 2016 -0700

    gpt: properly detect and repair invalid tables

    GPT_BOTH_VALID is 4 bits so simple a boolean check is not sufficient.
    This broken condition allowed gptprio to trust bogus disk locations in
    headers that were marked invalid causing arbitrary disk corruption.

commit 9af98c2bfd31a73b899268e67f01bca785681d52
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Mon Aug 22 16:44:30 2016 -0700

    gptrepair_test: fix typo in cleanup trap

commit d457364d1d811ad262519cf6dde3d098caf7c778
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Mon Aug 22 16:45:10 2016 -0700

    gptprio_test: check GPT is repaired when appropriate

commit 3a3e45823dd677b428ceb40d8963676aff63f8d2
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Mon Aug 22 18:30:56 2016 -0700

    fix checking alternate_lba

commit 72b178950d313d567dfdf11f403199370d81a9f3
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Wed Aug 24 16:14:20 2016 -0700

    gpt: fix partition table indexing and validation

    Portions of the code attempted to handle the fact that GPT entries on
    disk may be larger than the currently defined struct while others
    assumed the data could be indexed by the struct size directly. This
    never came up because no utility uses a size larger than 128 bytes but
    for the sake of safety we need to do this by the spec.

commit 1d358a2061f40ad89567754f4787d0c76001d48a
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Tue Aug 23 13:09:14 2016 -0700

    gpt: prefer disk size from header over firmware

    The firmware and the OS may disagree on the disk configuration and size.
    Although such a setup should be avoided users are unlikely to know about
    the problem, assuming everything behaves like the OS. Tolerate this as
    best we can and trust the reported on-disk location over the firmware
    when looking for the backup GPT. If the location is inaccessible report
    the error as best we can and move on.

commit 2ed905dc03c757c92064486b380f59166cc704e8
Author: Vito Caputo <vito.caputo@coreos.com>
Date:   Thu Aug 25 17:21:18 2016 -0700

    gpt: add helper for picking a valid header

    Eliminate some repetition in primary vs. backup header acquisition.

commit 4af1d7a8b7d0cefa41a1ea4df050b161ea6cdf50
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Tue Sep 20 13:06:05 2016 -0700

    gptrepair: fix status checking

    None of these status bit checks were correct. Fix and simplify.

commit a794435ae9f5b1a2e0281d36b10545c6e643fd8d
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Tue Sep 20 12:43:01 2016 -0700

    gpt: use inline functions for checking status bits

    This should prevent bugs like 6078f836 and 4268f3da.

commit 38cc185319b74d7d33ad380fe4d519fb0b0c85a6
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Tue Sep 20 13:40:11 2016 -0700

    gpt: allow repair function to noop

    Simplifies usage a little.

commit 2aeadda52929bb47089ef99c2bad0f928eadeffa
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Wed Sep 21 13:22:06 2016 -0700

    gpt: do not use an enum for status bit values

commit 34652e500d64dc747ca17091b4490f9adf93ff82
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Wed Sep 21 13:44:11 2016 -0700

    gpt: check header and entries status bits together

    Use the new status function which checks *_HEADER_VALID and
    *_ENTRIES_VALID bits together. It doesn't make sense for the header and
    entries bits to mismatch so don't allow for it.

commit 753dd9201306e8cd7092a1231ceb194524397b04
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Wed Sep 21 13:52:52 2016 -0700

    gpt: be more careful about relocating backup header

    The header was being relocated without checking the new location is
    actually safe. If the BIOS thinks the disk is smaller than the OS then
    repair may relocate the header into allocated space, failing the final
    validation check. So only move it if the disk has grown.

    Additionally, if the backup is valid then we can assume its current
    location is good enough and leave it as-is.

commit f1f618740d1379000b04130a632f4d53bc2392b8
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Wed Sep 21 14:33:48 2016 -0700

    gpt: selectively update fields during repair

    Just a little cleanup/refactor to skip touching data we don't need to.

commit 285368e3753b1dbd631c1f5a4a127b7321a6941f
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Wed Sep 21 14:55:19 2016 -0700

    gpt: always revalidate when recomputing checksums

    This ensures all code modifying GPT data include the same sanity check
    that repair does. If revalidation fails the status flags are left in the
    appropriate state.

commit f19f5cc49dc00752f6b267c2d580a25c31697afb
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Wed Sep 21 15:01:09 2016 -0700

    gpt: include backup-in-sync check in revalidation

commit 7b25acebc343895adf942975bba5a52ef3408437
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Wed Sep 21 15:29:55 2016 -0700

    gpt: read entries table at the same time as the header

    I personally think this reads easier. Also has the side effect of
    directly comparing the primary and backup tables instead of presuming
    they are equal if the crc32 matches.

commit edd01f055a8a8f922491ba7077bf26fcaf015516
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Wed Sep 21 16:02:53 2016 -0700

    gpt: report all revalidation errors

    Before returning an error that the primary or backup GPT is invalid push
    the existing error onto the stack so the user will be told what is bad.

commit 176fe49cf03ffdd72b8bd174a149032c3867ddde
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Thu Sep 22 10:00:27 2016 -0700

    gpt: rename and update documentation for grub_gpt_update

    The function now does more than just recompute checksums so give it a
    more general name to reflect that.

commit eb28d32081be2d224874c430345e7ef97bfbba07
Author: Michael Marineau <michael.marineau@coreos.com>
Date:   Thu Sep 22 11:18:42 2016 -0700

    gpt: write backup GPT first, skip if inaccessible.

    Writing the primary GPT before the backup may lead to a confusing
    situation: booting a freshly updated system could consistently fail and
    next boot will fall back to the old system if writing the primary works
    but writing the backup fails. If the backup is written first and fails
    the primary is left in the old state so the next boot will re-try and
    possibly fail in the exact same way. Making that repeatable should make
    it easier for users to identify the error.

    Additionally if the firmware and OS disagree on the disk size, making
    the backup inaccessible to GRUB, then just skip writing the backup.
    When this happens the automatic call to `coreos-setgoodroot` after boot
    will take care of repairing the backup.

commit 03b547c21ec3475980a54b71e909034ed5ed5254
Author: Matthew Garrett <mjg59@coreos.com>
Date:   Thu May 28 11:15:30 2015 -0700

    Add verity hash passthrough

    Read the verity hash from the kernel binary and pass it to the running
    system via the kernel command line
```
</details>

<details>
  <summary> (click to expand) Comprehensive log of the commits</summary>

```
f69a9e0fd gpt: start new GPT module
c26743a14 gpt: rename misnamed header location fields
94f04a532 gpt: record size of of the entries table
3d066264a gpt: consolidate crc32 computation code
dab6fac70 gpt: add new repair function to sync up primary and backup tables.
5e1829d41 gpt: add write function and gptrepair command
2cd009dff gpt: add a new generic GUID type
508b02fc8 gpt: new gptprio.next command for selecting priority based partitions
f8f6f790a gpt: split out checksum recomputation
d9bdbc104 gpt: move gpt guid printing function to common library
ffb13159f gpt: switch partition names to a 16 bit type
febf4666f tests: add some partitions to the gpt unit test data
67475f53e gpt: add search by partition label and uuid commands
d1270a2ba gpt: clean up little-endian crc32 computation
bacbed2c0 gpt: minor cleanup
1545295ad gpt: add search by disk uuid command
6d4ea4754 gpt: do not use disk sizes GRUB will reject as invalid later on
99959fa2f gpt: add verbose debug logging
f6b89ec31 gpt: improve validation of GPT headers
fa18d3a29 gpt: refuse to write to sector 0
b1ef48849 gpt: properly detect and repair invalid tables
9af98c2bf gptrepair_test: fix typo in cleanup trap
d457364d1 gptprio_test: check GPT is repaired when appropriate
3a3e45823 fix checking alternate_lba
72b178950 gpt: fix partition table indexing and validation
1d358a206 gpt: prefer disk size from header over firmware
2ed905dc0 gpt: add helper for picking a valid header
4af1d7a8b gptrepair: fix status checking
a794435ae gpt: use inline functions for checking status bits
38cc18531 gpt: allow repair function to noop
2aeadda52 gpt: do not use an enum for status bit values
34652e500 gpt: check header and entries status bits together
753dd9201 gpt: be more careful about relocating backup header
f1f618740 gpt: selectively update fields during repair
285368e37 gpt: always revalidate when recomputing checksums
f19f5cc49 gpt: include backup-in-sync check in revalidation
7b25acebc gpt: read entries table at the same time as the header
edd01f055 gpt: report all revalidation errors
176fe49cf gpt: rename and update documentation for grub_gpt_update
eb28d3208 gpt: write backup GPT first, skip if inaccessible.
03b547c21 Add verity hash passthrough
```
</details>
