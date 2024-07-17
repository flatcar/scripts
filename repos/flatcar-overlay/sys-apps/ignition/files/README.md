# Ignition patches

These patches bring Flatcar custom features (from a runtime execution point-of-view) to CoreOS's Ignition.

## Sync Ignition with the upstream

When a new upstream Ignition release is out, we need to backport the Flatcar patches on this new version.

For this, we can just apply the current patches and fix any broken stuff:

```bash
git clone https://github.com/coreos/ignition
cd ignition
git checkout "${RELEASE}"
git am --3way /path/to/coreos-overlay/sys-apps/ignition/files/00*
```

Once done, we can generate the new set of patches:
```
git format-patch "${RELEASE}"
```

Copy the new patches to `::coreos-overlay`
```
cp 00* /path/to/coreos-overlay/sys-apps/ignition/files/
```

:warning: We might need to update the applied patches' names in the Ignition ebuild.
When the new Ignition release adds a higher config version used from `config/config.go`, you also have to modify `files/0006-config-v3_4-convert-ignition-2.x-to-3.4-exp.patch` to be applied for this higher config version.
Note: the translation lifts to v3.1 and if it ever would be the same version as the highest, you also need to set the local `version` varable to meet the `if version == types.MaxVersion {` check.

## Ignition converter (ign-converter)

This converter is the central piece of auto-translation from Ignition config version 2 to Ignition config version 3. While we still support both version, we need to maintain it. It was initially on `coreos/ign-converter` then it has moved to `flatcar/ign-converter` to apply some logic (that could be upstreamed).

To ease the process with the previous section, we decided to "merge" ign-converter with Ignition. It's actually a copy of the package `v24tov31` and the associated tests to `config/v24tov31/` (and `config/util/translate.go`).

If we drop the support for Ignition config version 2, we can drop the following patches:
* `mod: add flatcar/ignition@0.36.2`
* `sum: go mod tidy`
* `vendor: go mod vendor`
* `config: add ignition translation`
* `config/v3_4: convert ignition 2.x to 3.4-exp`
