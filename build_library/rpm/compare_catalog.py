#!/usr/bin/env python3

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

"""
Compare installed RPM packages against the package catalog.

This script analyzes the relationship between:
1. The package catalog (expected RPM mappings from Portage packages)
2. Actually installed RPM packages in the built image

It identifies:
- Catalog entries that map to installed packages (covered)
- Catalog entries with no matching installed package (missing)
- Installed packages not in catalog (uncataloged/extra)
- SKIP entries in catalog (intentionally excluded)

Usage:
    ./compare_catalog.py [--build-dir PATH] [--format FORMAT] [--output FILE]

Options:
    --build-dir PATH    Path to build output directory
    --catalog PATH      Path to package_catalog.yaml
    --format FORMAT     Output format: 'text', 'json', 'markdown'
    --output FILE       Write output to file instead of stdout
"""

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None


# Package file locations relative to build directory
PACKAGE_FILES = {
    "base": "acl_production_image_packages.txt",
    "oem-azure": "oem-azure_packages.txt",
    "containerd": "rootfs-included-sysexts/containerd_packages.txt",
    "docker": "rootfs-included-sysexts/docker_packages.txt",
}

# File listing packages explicitly requested via dnf install
EXPLICIT_PACKAGES_FILE = ".rpm-packages-explicit"

COMPONENT_NAMES = {
    "base": "Base Image",
    "oem-azure": "OEM Azure",
    "containerd": "Containerd Sysext",
    "docker": "Docker Sysext",
}


def parse_package_catalog(catalog_path: Path) -> dict:
    """Parse package catalog from YAML."""
    catalog = {
        "mappings": {},  # portage_pkg -> [rpm_names]
        "skip": set(),  # portage packages marked SKIP
        "rpm_to_portage": defaultdict(list),  # rpm_name -> [portage_pkgs]
    }

    if not catalog_path.exists():
        return catalog

    return _parse_yaml_catalog(catalog_path, catalog)


def _parse_yaml_catalog(yaml_path: Path, catalog: dict) -> dict:
    """Parse package_catalog.yaml.

    Note: arch filtering is not applied here — all entries are included
    regardless of architecture. The bash loader handles arch filtering
    at build time based on BOARD.
    """
    if yaml is None:
        print(
            "WARNING: PyYAML not installed; cannot parse YAML catalog",
            file=sys.stderr,
        )
        return catalog

    with open(yaml_path, "r") as f:
        data = yaml.safe_load(f)

    packages = data.get("packages", {})
    for portage_pkg, value in packages.items():
        if isinstance(value, dict):
            # Object form: {rpm: ..., arch: ...}
            rpm_val = value.get("rpm", "SKIP")
            if isinstance(rpm_val, list):
                rpm_names = [str(r) for r in rpm_val]
            else:
                rpm_names = [str(rpm_val)]
        elif isinstance(value, list):
            # List of RPM names
            rpm_names = [str(r) for r in value]
        else:
            # Scalar: single RPM name or SKIP
            rpm_names = [str(value)]

        rpm_str = " ".join(rpm_names)
        if rpm_str == "SKIP":
            catalog["skip"].add(portage_pkg)
        else:
            catalog["mappings"][portage_pkg] = rpm_names
            for rpm_name in rpm_names:
                catalog["rpm_to_portage"][rpm_name].append(portage_pkg)

    return catalog


def parse_package_file(filepath: Path) -> set:
    """Parse a packages.txt file and return set of package names."""
    packages = set()
    if not filepath.exists():
        return packages

    with open(filepath, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            packages.add(line)

    return packages


def load_all_installed_packages(build_dir: Path) -> dict:
    """Load packages from all component files."""
    components = {}
    all_packages = set()

    for component, filename in PACKAGE_FILES.items():
        filepath = build_dir / filename
        packages = parse_package_file(filepath)
        components[component] = packages
        all_packages.update(packages)

    # Load explicitly installed packages (those dnf was told to install)
    explicit_file = build_dir / EXPLICIT_PACKAGES_FILE
    explicit_packages = parse_package_file(explicit_file)

    return {
        "by_component": components,
        "all": all_packages,
        "explicit": explicit_packages,
    }


def extract_package_name(full_name: str) -> str:
    """Extract base package name from full RPM name.

    RPM format: name-version-release.dist.arch
    Example: 'systemd-255-25.azl3.x86_64' -> 'systemd'
             'openssl-libs-3.3.5-1.azl3.x86_64' -> 'openssl-libs'
             'e2fsprogs-libs-1.47.0-2.azl3.x86_64' -> 'e2fsprogs-libs'
    """
    # Strip architecture suffix first (.x86_64, .noarch, etc.)
    name = re.sub(r"\.(x86_64|noarch|aarch64|i686)$", "", full_name)

    # RPM name-version-release format requires at least 2 hyphens
    # Working backwards: release is after last hyphen, version before that
    parts = name.split("-")

    if len(parts) < 3:
        # Not enough parts for name-version-release
        return parts[0] if parts else full_name

    # The release part typically contains .azl or similar
    # Work backwards to find the name portion
    # Strategy: find the rightmost segment that looks like a version number
    # (starts with digit and contains dots or is just digits)

    # Find the first version-like segment from the end
    name_end_idx = len(parts)
    for i in range(len(parts) - 1, 0, -1):
        part = parts[i]
        # Check if this looks like a version or release number
        if part and part[0].isdigit():
            name_end_idx = i
        else:
            # Found a non-version segment, stop here
            break

    return "-".join(parts[:name_end_idx])


def compare_catalog_to_installed(catalog: dict, installed: dict) -> dict:
    """Compare catalog entries against installed packages."""

    # Get all installed package base names
    installed_names = set()
    name_to_full = defaultdict(list)  # base_name -> [full_names]

    for full_name in installed["all"]:
        base_name = extract_package_name(full_name)
        installed_names.add(base_name)
        name_to_full[base_name].append(full_name)

    # Get explicitly installed package names
    explicit_names = set(installed.get("explicit", set()))

    # Expected RPM names from catalog (flatten the lists)
    expected_rpms = set()
    for rpm_names in catalog["mappings"].values():
        expected_rpms.update(rpm_names)

    results = {
        "covered_explicit": {},  # RPM name -> {portage_pkgs, installed_versions} (explicitly installed)
        "covered_deps": {},  # RPM name -> {portage_pkgs, installed_versions} (pulled as dependency)
        "missing": {},  # RPM name -> portage_pkgs that expect it
        "uncataloged": {},  # base_name -> full installed names
        "skip_entries": list(sorted(catalog["skip"])),
        "stats": {},
    }

    # Check which catalog entries have installed packages
    for rpm_name, portage_pkgs in catalog["rpm_to_portage"].items():
        if rpm_name in installed_names:
            entry = {
                "portage_packages": portage_pkgs,
                "installed_versions": name_to_full[rpm_name],
            }
            if rpm_name in explicit_names:
                results["covered_explicit"][rpm_name] = entry
            else:
                results["covered_deps"][rpm_name] = entry
        else:
            results["missing"][rpm_name] = portage_pkgs

    # Find installed packages not in catalog
    for base_name in installed_names:
        if base_name not in catalog["rpm_to_portage"]:
            results["uncataloged"][base_name] = name_to_full[base_name]

    # Calculate statistics
    covered_total = len(results["covered_explicit"]) + len(results["covered_deps"])
    results["stats"] = {
        "total_catalog_entries": len(catalog["mappings"]),
        "total_skip_entries": len(catalog["skip"]),
        "total_unique_rpms_in_catalog": len(expected_rpms),
        "total_installed_packages": len(installed["all"]),
        "total_unique_installed_names": len(installed_names),
        "total_explicit_packages": len(explicit_names),
        "covered_explicit_count": len(results["covered_explicit"]),
        "covered_deps_count": len(results["covered_deps"]),
        "covered_count": covered_total,
        "missing_count": len(results["missing"]),
        "uncataloged_count": len(results["uncataloged"]),
        "coverage_percent": (
            round(covered_total / len(expected_rpms) * 100, 1) if expected_rpms else 0
        ),
    }

    return results


def format_text(results: dict, catalog: dict, installed: dict) -> str:
    """Format results as plain text."""
    lines = []
    stats = results["stats"]

    lines.append("=" * 80)
    lines.append("Package Catalog vs Installed Packages Comparison")
    lines.append("=" * 80)
    lines.append("")

    # Statistics
    lines.append("SUMMARY")
    lines.append("-" * 40)
    lines.append(f"  Catalog entries (Portage->RPM):  {stats['total_catalog_entries']}")
    lines.append(f"  Catalog SKIP entries:            {stats['total_skip_entries']}")
    lines.append(
        f"  Unique RPM names in catalog:     {stats['total_unique_rpms_in_catalog']}"
    )
    lines.append(
        f"  Total installed packages:        {stats['total_installed_packages']}"
    )
    lines.append(
        f"  Unique installed base names:     {stats['total_unique_installed_names']}"
    )
    lines.append(
        f"  Explicitly installed packages:   {stats['total_explicit_packages']}"
    )
    lines.append("")
    lines.append(
        f"  Catalog RPMs installed:          {stats['covered_count']} ({stats['coverage_percent']}%)"
    )
    lines.append(
        f"    - Explicitly installed:        {stats['covered_explicit_count']}"
    )
    lines.append(f"    - Pulled as dependencies:      {stats['covered_deps_count']}")
    lines.append(f"  Catalog RPMs missing:            {stats['missing_count']}")
    lines.append(f"  Installed but uncataloged:       {stats['uncataloged_count']}")
    lines.append("")

    # Missing from catalog (expected but not installed)
    if results["missing"]:
        lines.append("MISSING (in catalog but not installed)")
        lines.append("-" * 60)
        for rpm_name in sorted(results["missing"].keys()):
            portage_pkgs = results["missing"][rpm_name]
            lines.append(f"  {rpm_name}")
            for pkg in portage_pkgs:
                lines.append(f"    <- {pkg}")
        lines.append("")

    # Uncataloged (installed but not in catalog)
    if results["uncataloged"]:
        lines.append("UNCATALOGED (installed but not in catalog)")
        lines.append("-" * 60)
        lines.append("  These packages are installed but have no catalog entry.")
        lines.append("  Consider adding them to package_catalog.yaml")
        lines.append("")
        for base_name in sorted(results["uncataloged"].keys()):
            full_names = results["uncataloged"][base_name]
            lines.append(f"  {base_name}")
            for full in full_names:
                lines.append(f"    -> {full}")
        lines.append("")

    # Covered - Explicitly installed
    if results["covered_explicit"]:
        lines.append("COVERED - EXPLICIT (catalog entries explicitly installed)")
        lines.append("-" * 60)
        for rpm_name in sorted(results["covered_explicit"].keys()):
            data = results["covered_explicit"][rpm_name]
            versions = ", ".join(data["installed_versions"][:2])
            if len(data["installed_versions"]) > 2:
                versions += f" (+{len(data['installed_versions'])-2} more)"
            lines.append(f"  {rpm_name}: {versions}")
        lines.append("")

    # Covered - Dependencies
    if results["covered_deps"]:
        lines.append("COVERED - DEPENDENCIES (catalog entries pulled as deps)")
        lines.append("-" * 60)
        for rpm_name in sorted(results["covered_deps"].keys()):
            data = results["covered_deps"][rpm_name]
            versions = ", ".join(data["installed_versions"][:2])
            if len(data["installed_versions"]) > 2:
                versions += f" (+{len(data['installed_versions'])-2} more)"
            lines.append(f"  {rpm_name}: {versions}")
        lines.append("")

    # SKIP entries
    if results["skip_entries"]:
        lines.append("SKIP ENTRIES (intentionally excluded)")
        lines.append("-" * 60)
        for pkg in results["skip_entries"]:
            lines.append(f"  {pkg}")

    return "\n".join(lines)


def format_markdown(results: dict, catalog: dict, installed: dict) -> str:
    """Format results as Markdown."""
    lines = []
    stats = results["stats"]

    lines.append("# Package Catalog Comparison Report")
    lines.append("")

    # Summary table
    lines.append("## Summary")
    lines.append("")
    lines.append("| Metric | Value |")
    lines.append("|--------|-------|")
    lines.append(
        f"| Catalog entries (Portage→RPM) | {stats['total_catalog_entries']} |"
    )
    lines.append(f"| Catalog SKIP entries | {stats['total_skip_entries']} |")
    lines.append(
        f"| Unique RPM names in catalog | {stats['total_unique_rpms_in_catalog']} |"
    )
    lines.append(f"| Total installed packages | {stats['total_installed_packages']} |")
    lines.append(
        f"| Unique installed base names | {stats['total_unique_installed_names']} |"
    )
    lines.append(
        f"| Explicitly installed packages | {stats['total_explicit_packages']} |"
    )
    lines.append(f"| **Catalog coverage** | **{stats['coverage_percent']}%** |")
    lines.append("")

    # Status breakdown
    lines.append("### Status Breakdown")
    lines.append("")
    lines.append(
        f"- ✅ **Covered (explicit)**: {stats['covered_explicit_count']} catalog RPMs explicitly installed"
    )
    lines.append(
        f"- 📦 **Covered (deps)**: {stats['covered_deps_count']} catalog RPMs pulled as dependencies"
    )
    lines.append(
        f"- ❌ **Missing**: {stats['missing_count']} catalog RPMs not found in installed packages"
    )
    lines.append(
        f"- ⚠️ **Uncataloged**: {stats['uncataloged_count']} installed packages not in catalog"
    )
    lines.append("")

    # Missing
    if results["missing"]:
        lines.append("## ❌ Missing Packages")
        lines.append("")
        lines.append("These packages are defined in the catalog but not installed:")
        lines.append("")
        lines.append("| RPM Name | Portage Package(s) |")
        lines.append("|----------|-------------------|")
        for rpm_name in sorted(results["missing"].keys()):
            portage_pkgs = ", ".join(f"`{p}`" for p in results["missing"][rpm_name])
            lines.append(f"| `{rpm_name}` | {portage_pkgs} |")
        lines.append("")

    # Uncataloged
    if results["uncataloged"]:
        lines.append("## ⚠️ Uncataloged Packages")
        lines.append("")
        lines.append("These packages are installed but not in the catalog:")
        lines.append("")
        lines.append("| Base Name | Installed Version(s) |")
        lines.append("|-----------|---------------------|")
        for base_name in sorted(results["uncataloged"].keys()):
            full_names = results["uncataloged"][base_name]
            versions = ", ".join(f"`{v}`" for v in full_names[:2])
            if len(full_names) > 2:
                versions += f" +{len(full_names)-2} more"
            lines.append(f"| `{base_name}` | {versions} |")
        lines.append("")

        # Suggestions for catalog entries
        lines.append("### Suggested Catalog Entries")
        lines.append("")
        lines.append("```bash")
        lines.append("# Add to package_catalog.yaml:")
        for base_name in sorted(results["uncataloged"].keys())[:20]:
            lines.append(f'    ["CATEGORY/{base_name}"]="{base_name}"')
        if len(results["uncataloged"]) > 20:
            lines.append(f"    # ... and {len(results['uncataloged'])-20} more")
        lines.append("```")
        lines.append("")

    # Covered - Explicit (collapsed)
    lines.append("## ✅ Covered Packages (Explicit)")
    lines.append("")
    lines.append("<details>")
    lines.append(
        "<summary>Click to expand ({} packages)</summary>".format(
            stats["covered_explicit_count"]
        )
    )
    lines.append("")
    lines.append("| RPM Name | Installed Version |")
    lines.append("|----------|-------------------|")
    for rpm_name in sorted(results["covered_explicit"].keys()):
        data = results["covered_explicit"][rpm_name]
        version = data["installed_versions"][0] if data["installed_versions"] else "-"
        lines.append(f"| `{rpm_name}` | `{version}` |")
    lines.append("")
    lines.append("</details>")
    lines.append("")

    # Covered - Dependencies (collapsed)
    lines.append("## 📦 Covered Packages (Dependencies)")
    lines.append("")
    lines.append("<details>")
    lines.append(
        "<summary>Click to expand ({} packages)</summary>".format(
            stats["covered_deps_count"]
        )
    )
    lines.append("")
    lines.append("| RPM Name | Installed Version |")
    lines.append("|----------|-------------------|")
    for rpm_name in sorted(results["covered_deps"].keys()):
        data = results["covered_deps"][rpm_name]
        version = data["installed_versions"][0] if data["installed_versions"] else "-"
        lines.append(f"| `{rpm_name}` | `{version}` |")
    lines.append("")
    lines.append("</details>")
    lines.append("")

    # SKIP entries (collapsed)
    if results["skip_entries"]:
        lines.append("## ⏭️ Skipped Packages")
        lines.append("")
        lines.append("<details>")
        lines.append(
            "<summary>Click to expand ({} packages)</summary>".format(
                len(results["skip_entries"])
            )
        )
        lines.append("")
        lines.append("These Portage packages are intentionally excluded in RPM mode:")
        lines.append("")
        for pkg in results["skip_entries"]:
            lines.append(f"- `{pkg}`")
        lines.append("")
        lines.append("</details>")

    return "\n".join(lines)


def format_json(results: dict, catalog: dict, installed: dict) -> str:
    """Format results as JSON."""
    output = {
        "summary": results["stats"],
        "missing": {k: v for k, v in results["missing"].items()},
        "uncataloged": {k: v for k, v in results["uncataloged"].items()},
        "covered_explicit": {k: v for k, v in results["covered_explicit"].items()},
        "covered_deps": {k: v for k, v in results["covered_deps"].items()},
        "skip_entries": results["skip_entries"],
    }
    return json.dumps(output, indent=2, default=list)


def main():
    parser = argparse.ArgumentParser(
        description="Compare installed RPM packages against package catalog",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )

    script_dir = Path(__file__).parent
    default_build_dir = (
        script_dir.parent / "__build__" / "images" / "images" / "amd64-usr" / "latest"
    )
    default_catalog = (
        script_dir.parent / "build_library" / "rpm" / "package_catalog.yaml"
    )

    parser.add_argument(
        "--build-dir",
        "-d",
        type=Path,
        default=default_build_dir,
        help="Path to build output directory",
    )
    parser.add_argument(
        "--catalog",
        "-c",
        type=Path,
        default=default_catalog,
        help="Path to package_catalog.yaml",
    )
    parser.add_argument(
        "--format",
        "-f",
        choices=["text", "json", "markdown", "md"],
        default="text",
        help="Output format (default: text)",
    )
    parser.add_argument(
        "--output", "-o", type=Path, help="Write output to file instead of stdout"
    )
    parser.add_argument(
        "--quiet", "-q", action="store_true", help="Suppress informational messages"
    )

    args = parser.parse_args()

    # Validate paths
    if not args.build_dir.exists():
        print(f"Error: Build directory not found: {args.build_dir}", file=sys.stderr)
        sys.exit(1)

    if not args.catalog.exists():
        print(f"Error: Catalog file not found: {args.catalog}", file=sys.stderr)
        sys.exit(1)

    if not args.quiet:
        print(f"Loading catalog from: {args.catalog}", file=sys.stderr)
        print(f"Loading packages from: {args.build_dir}", file=sys.stderr)

    # Load data
    catalog = parse_package_catalog(args.catalog)
    installed = load_all_installed_packages(args.build_dir)

    if not args.quiet:
        print(f"Found {len(catalog['mappings'])} catalog mappings", file=sys.stderr)
        print(f"Found {len(installed['all'])} installed packages", file=sys.stderr)

    # Compare
    results = compare_catalog_to_installed(catalog, installed)

    # Format output
    fmt = args.format.lower()
    if fmt == "md":
        fmt = "markdown"

    if fmt == "text":
        output = format_text(results, catalog, installed)
    elif fmt == "json":
        output = format_json(results, catalog, installed)
    elif fmt == "markdown":
        output = format_markdown(results, catalog, installed)
    else:
        print(f"Unknown format: {fmt}", file=sys.stderr)
        sys.exit(1)

    # Write output
    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
            f.write("\n")
        if not args.quiet:
            print(f"Output written to: {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()
