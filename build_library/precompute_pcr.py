#!/usr/bin/python3
"""Precompute expected TPM PCR 4, 8, and 9 values for a Flatcar boot.

PCR 4: Boot chain EFI binaries (shim, GRUB, kernel) measured via PE
       Authenticode hash, plus firmware EV_EFI_ACTION and EV_SEPARATOR.
PCR 8: GRUB commands and kernel command line measured as plain strings.
PCR 9: GRUB source'd config files and loaded kernel measured by file content.

Usage:
    # Compute PCR 4 from EFI binaries:
    python3 precompute_pcr.py pcr4 --shim bootx64.efi --grub grubx64.efi --kernel vmlinuz-a

    # Compute PCR 9 from kernel file and optional OEM grub.cfg:
    python3 precompute_pcr.py pcr9 --kernel vmlinuz-a --oem-grub-cfg /path/to/oem/grub.cfg

    # Compute PCR 8 from a file listing grub commands (one per line):
    python3 precompute_pcr.py pcr8 --commands-file grub_commands.txt

    # Compute all PCRs at once:
    python3 precompute_pcr.py all --shim bootx64.efi --grub grubx64.efi --kernel vmlinuz-a \\
        --oem-grub-cfg /path/to/oem/grub.cfg --commands-file grub_commands.txt

    # Parse an existing eventlog YAML and replay PCR computation:
    python3 precompute_pcr.py replay --eventlog eventlog.yaml

Reference:
    - build_library/generate_grub_hashes.py  — generates PCR hash configs for grub components
    - build_library/generate_kernel_hash.py  — generates PCR hash config for kernel
    - build_library/grub.cfg                 — main GRUB configuration template

PCR measurement details (SHA-256):
    PCR 4:
      1. EV_EFI_ACTION "Calling EFI Application from Boot Option"  (always)
      2. EV_SEPARATOR 0x00000000                                    (always)
      3. PE Authenticode hash of shim   (bootx64.efi)
      4. PE Authenticode hash of GRUB   (grubx64.efi)
      5. PE Authenticode hash of kernel (vmlinuz-a)

    PCR 8:
      Each GRUB command is measured as SHA-256(command_text) where
      command_text is the raw command WITHOUT the "grub_cmd: " prefix
      shown in event logs.  The kernel command line is measured as
      SHA-256(cmdline_text) without the "kernel_cmdline: " prefix.

    PCR 9:
      Each source'd config file is measured as SHA-256(file_contents).
      The loaded kernel is measured as SHA-256(kernel_file_contents).
"""

import argparse
import hashlib
import json
import subprocess
import sys


# ---------------------------------------------------------------------------
# PE Authenticode hash via pesign(1)
# Used by UEFI firmware to measure EFI binaries into PCR 4.
# ---------------------------------------------------------------------------

def pe_authenticode_hash(filepath, hash_algo='sha256'):
    """Compute the PE Authenticode hash of an EFI binary using pesign(1).

    This invokes 'pesign --hash' which computes the hash per the
    Microsoft PE Authenticode spec (excluding CheckSum, Certificate Table
    directory entry, and Certificate Table data), matching UEFI firmware
    behavior for EV_EFI_BOOT_SERVICES_APPLICATION measurements.
    """
    result = subprocess.run(
        ['pesign', '-h', '-i', filepath, '-d', hash_algo],
        capture_output=True, text=True, check=True)
    # Output format: "hash: <hex>\n"
    return result.stdout.strip().split(': ', 1)[1]


# ---------------------------------------------------------------------------
# PCR extension
# ---------------------------------------------------------------------------

def pcr_extend(pcr_value, digest_hex, hash_algo='sha256'):
    """Extend a PCR value: new_pcr = HASH(old_pcr || digest)."""
    digest = bytes.fromhex(digest_hex)
    return hashlib.new(hash_algo, pcr_value + digest).digest()


def pcr_init(hash_algo='sha256'):
    """Return initial PCR value (all zeros)."""
    digest_size = hashlib.new(hash_algo).digest_size
    return b'\x00' * digest_size


def hash_bytes(data, hash_algo='sha256'):
    """Hash raw bytes."""
    return hashlib.new(hash_algo, data).hexdigest()


def hash_string(s, hash_algo='sha256'):
    """Hash a UTF-8 string (no null terminator — matches GRUB measurements)."""
    return hashlib.new(hash_algo, s.encode('utf-8')).hexdigest()


def hash_file(filepath, hash_algo='sha256'):
    """Hash file contents."""
    h = hashlib.new(hash_algo)
    with open(filepath, 'rb') as f:
        while True:
            chunk = f.read(65536)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


# ---------------------------------------------------------------------------
# PCR 4: EFI boot chain
# ---------------------------------------------------------------------------

# EV_EFI_ACTION string measured by firmware before loading the first
# boot application.  This is a well-known constant.
EV_EFI_ACTION_BOOT = "Calling EFI Application from Boot Option"

# EV_SEPARATOR event data: 4 zero bytes.  Measured by firmware to
# separate pre-OS and OS-present measurements.
EV_SEPARATOR_DATA = b"\x00\x00\x00\x00"


def compute_pcr4(shim_path, grub_path, kernel_path, hash_algo='sha256'):
    """Compute PCR 4 from the EFI boot chain binaries.

    The UEFI firmware measures:
      1. EV_EFI_ACTION  "Calling EFI Application from Boot Option"
      2. EV_SEPARATOR   (4 zero bytes)
    Then each EFI application is measured with its PE Authenticode hash:
      3. shim    (bootx64.efi)
      4. GRUB    (grubx64.efi)
      5. kernel  (vmlinuz-a)
    """
    pcr = pcr_init(hash_algo)

    # Firmware events
    action_digest = hash_bytes(EV_EFI_ACTION_BOOT.encode('utf-8'), hash_algo)
    pcr = pcr_extend(pcr, action_digest, hash_algo)

    separator_digest = hash_bytes(EV_SEPARATOR_DATA, hash_algo)
    pcr = pcr_extend(pcr, separator_digest, hash_algo)

    # EFI application measurements (PE Authenticode hashes)
    for label, path in [("shim", shim_path),
                        ("grub", grub_path),
                        ("kernel", kernel_path)]:
        digest = pe_authenticode_hash(path, hash_algo)
        pcr = pcr_extend(pcr, digest, hash_algo)

    return pcr.hex()


# ---------------------------------------------------------------------------
# PCR 8: GRUB commands and kernel command line
# ---------------------------------------------------------------------------

def compute_pcr8(commands, hash_algo='sha256'):
    """Compute PCR 8 from a list of GRUB command strings.

    Each command is measured as hash(command_text) where command_text
    is the raw grub command (e.g. "set prefix=...") WITHOUT any
    "grub_cmd: " prefix.  The kernel command line is also measured
    the same way, as the raw command line text without
    "kernel_cmdline: " prefix.

    Args:
        commands: list of command strings, one per GRUB measurement.
            Lines starting with "grub_cmd: " or "kernel_cmdline: " will
            have the prefix stripped automatically for convenience.
    """
    pcr = pcr_init(hash_algo)

    for cmd in commands:
        # Strip common prefixes if present (convenience for eventlog copy-paste)
        for prefix in ("grub_cmd: ", "kernel_cmdline: "):
            if cmd.startswith(prefix):
                cmd = cmd[len(prefix):]
                break
        digest = hash_string(cmd, hash_algo)
        pcr = pcr_extend(pcr, digest, hash_algo)

    return pcr.hex()


def load_commands_file(filepath):
    """Load GRUB commands from a text file (one command per line).

    Empty lines and lines starting with '#' are skipped.
    """
    commands = []
    with open(filepath, 'r') as f:
        for line in f:
            line = line.rstrip('\n')
            if line and not line.startswith('#'):
                commands.append(line)
    return commands


# ---------------------------------------------------------------------------
# PCR 9: GRUB source'd files and loaded kernel
# ---------------------------------------------------------------------------

def compute_pcr9(kernel_path, oem_grub_cfg_paths=None, hash_algo='sha256'):
    """Compute PCR 9 from measured files.

    GRUB measures into PCR 9:
      1. Content of each source'd config file (e.g. OEM grub.cfg)
      2. Content of the loaded kernel file

    The measurement order matches the boot sequence: OEM configs
    are sourced before the kernel is loaded.

    Args:
        kernel_path: path to vmlinuz-a or vmlinuz-b
        oem_grub_cfg_paths: list of paths to OEM grub.cfg files that
            are source'd during boot (measured before the kernel)
    """
    pcr = pcr_init(hash_algo)

    # Source'd config files (OEM grub.cfg etc.)
    if oem_grub_cfg_paths:
        for cfg_path in oem_grub_cfg_paths:
            digest = hash_file(cfg_path, hash_algo)
            pcr = pcr_extend(pcr, digest, hash_algo)

    # Kernel file content
    digest = hash_file(kernel_path, hash_algo)
    pcr = pcr_extend(pcr, digest, hash_algo)

    return pcr.hex()


# ---------------------------------------------------------------------------
# Eventlog replay
# ---------------------------------------------------------------------------

def replay_eventlog(eventlog_path, hash_algo='sha256'):
    """Parse a YAML eventlog and replay PCR 4, 8, 9 extensions.

    Reads the event digests directly from the log and extends them
    to reproduce the final PCR values.  This is useful for verification.
    """
    try:
        import yaml
    except ImportError:
        # Minimal YAML-like parser for the eventlog format
        return replay_eventlog_simple(eventlog_path, hash_algo)

    with open(eventlog_path, 'r') as f:
        data = yaml.safe_load(f)

    pcrs = {}
    algo_map = {'sha1': 'sha1', 'sha256': 'sha256', 'sha384': 'sha384'}

    for event in data.get('events', []):
        pcr_index = event.get('PCRIndex')
        if pcr_index not in (4, 8, 9):
            continue
        digests = event.get('Digests', [])
        for d in digests:
            algo = algo_map.get(d.get('AlgorithmId'))
            if algo != hash_algo:
                continue
            digest_hex = d['Digest']
            key = pcr_index
            if key not in pcrs:
                pcrs[key] = pcr_init(hash_algo)
            pcrs[key] = pcr_extend(pcrs[key], digest_hex, hash_algo)

    return {k: v.hex() for k, v in sorted(pcrs.items())}


def replay_eventlog_simple(eventlog_path, hash_algo='sha256'):
    """Simple eventlog parser without PyYAML dependency.

    Parses the structured eventlog YAML format to extract PCR index,
    algorithm, and digest for events targeting PCR 4, 8, and 9.
    """
    import re

    pcrs = {}
    current_pcr = None
    in_digests = False
    current_algo = None

    with open(eventlog_path, 'r') as f:
        for line in f:
            line = line.rstrip()

            m = re.match(r'\s+PCRIndex:\s+(\d+)', line)
            if m:
                current_pcr = int(m.group(1))
                in_digests = False
                continue

            if 'Digests:' in line:
                in_digests = True
                continue

            if in_digests:
                m = re.match(r'\s+- AlgorithmId:\s+(\S+)', line)
                if m:
                    current_algo = m.group(1)
                    continue

                m = re.match(r'\s+Digest:\s+"([0-9a-fA-F]+)"', line)
                if m and current_algo == hash_algo and current_pcr in (4, 8, 9):
                    digest_hex = m.group(1)
                    if current_pcr not in pcrs:
                        pcrs[current_pcr] = pcr_init(hash_algo)
                    pcrs[current_pcr] = pcr_extend(
                        pcrs[current_pcr], digest_hex, hash_algo)
                    continue

            if re.match(r'\s+EventSize:', line) or re.match(r'\s+Event', line):
                in_digests = False

    return {k: v.hex() for k, v in sorted(pcrs.items())}


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Precompute TPM PCR 4, 8, and 9 values for Flatcar boot.')
    parser.add_argument('--algo', default='sha256',
                        choices=['sha1', 'sha256', 'sha384'],
                        help='Hash algorithm (default: sha256)')
    parser.add_argument('--json', action='store_true',
                        help='Output results as JSON')
    sub = parser.add_subparsers(dest='command')

    # pcr4
    p4 = sub.add_parser('pcr4', help='Compute PCR 4 from EFI binaries')
    p4.add_argument('--shim', required=True, help='Path to shim (bootx64.efi)')
    p4.add_argument('--grub', required=True, help='Path to GRUB (grubx64.efi)')
    p4.add_argument('--kernel', required=True, help='Path to kernel (vmlinuz-a)')

    # pcr8
    p8 = sub.add_parser('pcr8',
                         help='Compute PCR 8 from GRUB command list')
    p8.add_argument('--commands-file', required=True,
                    help='File with GRUB commands, one per line')

    # pcr9
    p9 = sub.add_parser('pcr9',
                         help='Compute PCR 9 from kernel and config files')
    p9.add_argument('--kernel', required=True, help='Path to kernel (vmlinuz-a)')
    p9.add_argument('--oem-grub-cfg', nargs='*', default=[],
                    help='Path(s) to OEM grub.cfg file(s) sourced during boot')

    # all
    pa = sub.add_parser('all', help='Compute PCR 4, 8, and 9')
    pa.add_argument('--shim', required=True, help='Path to shim (bootx64.efi)')
    pa.add_argument('--grub', required=True, help='Path to GRUB (grubx64.efi)')
    pa.add_argument('--kernel', required=True, help='Path to kernel (vmlinuz-a)')
    pa.add_argument('--commands-file', required=True,
                    help='File with GRUB commands, one per line')
    pa.add_argument('--oem-grub-cfg', nargs='*', default=[],
                    help='Path(s) to OEM grub.cfg file(s) sourced during boot')

    # replay
    pr = sub.add_parser('replay',
                         help='Replay an eventlog to verify PCR values')
    pr.add_argument('--eventlog', required=True, help='Path to eventlog YAML')

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    results = {}

    if args.command == 'pcr4':
        results['pcr4'] = compute_pcr4(
            args.shim, args.grub, args.kernel, args.algo)

    elif args.command == 'pcr8':
        commands = load_commands_file(args.commands_file)
        results['pcr8'] = compute_pcr8(commands, args.algo)

    elif args.command == 'pcr9':
        results['pcr9'] = compute_pcr9(
            args.kernel,
            args.oem_grub_cfg if args.oem_grub_cfg else None,
            args.algo)

    elif args.command == 'all':
        results['pcr4'] = compute_pcr4(
            args.shim, args.grub, args.kernel, args.algo)
        commands = load_commands_file(args.commands_file)
        results['pcr8'] = compute_pcr8(commands, args.algo)
        results['pcr9'] = compute_pcr9(
            args.kernel,
            args.oem_grub_cfg if args.oem_grub_cfg else None,
            args.algo)

    elif args.command == 'replay':
        results = {("pcr%d" % k): v
                   for k, v in replay_eventlog(
                       args.eventlog, args.algo).items()}

    if args.json:
        print(json.dumps(results, indent=2))
    else:
        for name, value in sorted(results.items()):
            print(f"{name}: {value}")


if __name__ == '__main__':
    main()
