#!/usr/bin/env python3

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Parse package_catalog.yaml and output TSV lines for shell consumption.
# Each output line: key<TAB>rpm_value<TAB>arch_or_null
#
# Entry formats handled:
#   key: scalar        →  key\tscalar\tnull
#   key:\n  - item     →  key\titem1 item2\tnull
#   key:\n  rpm: ..\n  arch: ..  →  key\trpm\tarch
#
# No external libraries required (stdlib only).

import re
import sys


def strip_yaml_comment(val):
    """Strip inline YAML comments (e.g. 'SKIP  # reason' -> 'SKIP')."""
    m = re.match(r"^(.*?)\s+#", val)
    return m.group(1) if m else val


def parse_catalog(path):
    with open(path) as f:
        lines = f.readlines()
    in_packages = False
    current_key = None
    current_list = []
    current_obj = {}
    mode = None  # 'list', 'obj', or None

    def flush():
        if current_key is None:
            return
        if mode == "list":
            rpms = " ".join(current_list)
            print(f"{current_key}\t{rpms}\tnull")
        elif mode == "obj":
            rpm = current_obj.get("rpm", "SKIP")
            arch = current_obj.get("arch", "null")
            print(f"{current_key}\t{rpm}\t{arch}")

    for raw in lines:
        line = raw.rstrip("\n")
        stripped = line.lstrip()
        # Skip comments and blank lines
        if not stripped or stripped.startswith("#"):
            continue
        # Detect 'packages:' top-level key
        if line == "packages:":
            in_packages = True
            continue
        if not in_packages:
            continue
        indent = len(line) - len(stripped)
        # Top-level entries under packages: are at indent 2
        if indent == 2:
            # Flush previous entry
            flush()
            current_list = []
            current_obj = {}
            mode = None
            # Parse this line: '  key: value' or '  key:'
            m = re.match(r"^  ([^:]+):\s*(.*)", line)
            if not m:
                current_key = None
                continue
            current_key = m.group(1).strip()
            val = strip_yaml_comment(m.group(2).strip())
            if val:
                # Scalar value - output immediately
                print(f"{current_key}\t{val}\tnull")
                current_key = None
            # else: multi-line (list or object) - wait for children
        elif indent >= 4 and current_key:
            # Child of current entry
            if stripped.startswith("- "):
                mode = "list"
                current_list.append(strip_yaml_comment(stripped[2:].strip()))
            elif ":" in stripped:
                mode = "obj"
                k, v = stripped.split(":", 1)
                current_obj[k.strip()] = strip_yaml_comment(v.strip())
    # Flush last entry
    flush()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <catalog.yaml>", file=sys.stderr)
        sys.exit(1)
    parse_catalog(sys.argv[1])
