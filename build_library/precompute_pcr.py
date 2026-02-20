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
      5. PE Authenticode hash of kernel (vmlinuz-a)  [SecureBoot only]

    When SecureBoot is disabled, the kernel is loaded by GRUB without
    shim verification, and GRUB does not measure it into PCR 4.  Use
    --no-sb (or kernel_path=None) to skip the kernel measurement.

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


def compute_pcr4(shim_path, grub_path, kernel_path=None, hash_algo='sha256'):
    """Compute PCR 4 from the EFI boot chain binaries.

    The UEFI firmware measures:
      1. EV_EFI_ACTION  "Calling EFI Application from Boot Option"
      2. EV_SEPARATOR   (4 zero bytes)
    Then each EFI application is measured with its PE Authenticode hash:
      3. shim    (bootx64.efi)
      4. GRUB    (grubx64.efi)
      5. kernel  (vmlinuz-a)  — only when SecureBoot is enabled

    When SecureBoot is disabled, GRUB loads the kernel directly without
    shim verification, and the kernel is NOT measured into PCR 4.  Pass
    kernel_path=None to model this case.
    """
    pcr = pcr_init(hash_algo)

    # Firmware events
    action_digest = hash_bytes(EV_EFI_ACTION_BOOT.encode('utf-8'), hash_algo)
    pcr = pcr_extend(pcr, action_digest, hash_algo)

    separator_digest = hash_bytes(EV_SEPARATOR_DATA, hash_algo)
    pcr = pcr_extend(pcr, separator_digest, hash_algo)

    # EFI application measurements (PE Authenticode hashes)
    binaries = [shim_path, grub_path]
    if kernel_path:
        binaries.append(kernel_path)
    for path in binaries:
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
    Literal '\\n' sequences are unescaped back to newlines to support
    multi-line commands (e.g. menuentry blocks) produced by --print-commands.
    """
    commands = []
    with open(filepath, 'r') as f:
        for line in f:
            line = line.rstrip('\n')
            if line and not line.startswith('#'):
                commands.append(line.replace('\\n', '\n'))
    return commands


# ---------------------------------------------------------------------------
# GRUB config evaluator for Flatcar grub.cfg
# ---------------------------------------------------------------------------

class GrubEvaluator:
    """Evaluate a Flatcar grub.cfg and produce the PCR 8 command list.

    This is a minimal GRUB script interpreter that handles the subset
    of GRUB scripting used by the Flatcar grub.cfg: variable assignments,
    conditionals, function definitions/calls, source, menuentry, and
    the test ([) builtin.

    Runtime filesystem state and GRUB environment variables are provided
    by the caller via constructor arguments.

    Args:
        grub_cfg: text content of the main grub.cfg (with @@MOUNTUSR@@
            already replaced)
        env: dict of pre-set GRUB environment variables. Must include
            at minimum 'root' (e.g. 'hd0,gpt1').  Common variables:
              root           - boot disk partition (e.g. 'hd0,gpt1')
              grub_platform  - 'efi', 'pc', or 'xen'
              grub_cpu       - 'x86_64' or 'arm64'
              prefix         - initial prefix (overwritten by grub.cfg)
        oem_partition: value that 'search --set oem --part-label OEM'
            should return (e.g. 'hd0,gpt6'), or None if no OEM partition
        oem_grub_cfg: text content of the OEM grub.cfg, or None
        existing_files: set of file paths that exist on the boot disk,
            used for '[ -f path ]' tests.  Paths should use the GRUB
            format '(device)/path' (e.g. '(hd0,gpt1)/flatcar/first_boot')
        usr_uuid: UUID returned by gptprio.next (selects USR-A or USR-B)
        menuentry: which menuentry --id to boot (default: 'flatcar')
    """

    def __init__(self, grub_cfg, env=None, oem_partition=None,
                 oem_grub_cfg=None, existing_files=None,
                 usr_uuid=None, menuentry='flatcar'):
        self.env = dict(env) if env else {}
        self.oem_partition = oem_partition
        self.oem_grub_cfg = oem_grub_cfg
        self.existing_files = set(existing_files) if existing_files else set()
        self.usr_uuid = usr_uuid or ''
        self.menuentry = menuentry
        self.commands = []       # PCR 8 measured commands
        self.functions = {}      # name -> list of lines
        self.kernel_cmdline = None
        self._raw_text = grub_cfg

        # If OEM partition and grub.cfg are provided, register the file
        if self.oem_partition and self.oem_grub_cfg is not None:
            self.existing_files.add(f'({self.oem_partition})/grub.cfg')

        lines = self._preprocess(grub_cfg)
        self._execute(lines)

    def _preprocess(self, text):
        """Split script into logical lines, joining continuation lines."""
        result = []
        for line in text.splitlines():
            stripped = line.strip()
            if not stripped or stripped.startswith('#'):
                continue
            result.append(stripped)
        return result

    def _menuentry_source(self, text, start_token_line):
        """Reconstruct the raw source of a menuentry block for measurement.

        GRUB measures menuentry commands using the original source text
        with quotes removed from the command line but body lines
        preserved with original whitespace. Variables in the body are
        NOT expanded.

        Returns: the measured string for the menuentry definition.
        """
        # Find the menuentry line in the original text
        raw_lines = text.splitlines()
        # Find a line starting with 'menuentry' that matches
        # the stripped start_token_line
        start_idx = None
        for idx, raw in enumerate(raw_lines):
            if raw.strip() == start_token_line:
                start_idx = idx
                break
        if start_idx is None:
            return start_token_line

        # Collect until closing }
        depth = 0
        end_idx = start_idx
        for idx in range(start_idx, len(raw_lines)):
            for ch in raw_lines[idx]:
                if ch == '{':
                    depth += 1
                elif ch == '}':
                    depth -= 1
            if depth == 0 and idx > start_idx:
                end_idx = idx
                break

        # Build the measured source: first line (quote-removed) + body + }
        # First line: tokenize and expand/unquote, then join
        first_tokens = self._tokenize(start_token_line)
        # Remove { from the end
        if first_tokens and first_tokens[-1] == '{':
            first_tokens = first_tokens[:-1]
        measured_first = ' '.join(self._expand_and_unquote(t) for t in first_tokens)
        measured_first += ' {'

        # Body lines: use raw source (no stripping, no expansion)
        body_lines = raw_lines[start_idx + 1:end_idx]
        # The closing } line
        result = measured_first
        for bl in body_lines:
            result += '\n' + bl
        result += '\n}'
        return result

    def _expand_and_unquote(self, s):
        """Expand variables and remove quotes from a GRUB word.

        Returns the expanded string as a single value (no word splitting).

        GRUB processes words by:
        1. Expanding $var / ${var} references
        2. Removing quote characters (double and single quotes)
        3. Inside double quotes, variables are expanded
        4. Inside single quotes, text is literal (no expansion)
        """
        result = []
        i = 0
        while i < len(s):
            if s[i] == '"':
                # Double-quoted section: expand variables, remove quotes
                i += 1
                while i < len(s) and s[i] != '"':
                    if s[i] == '$':
                        val, consumed = self._expand_var(s, i)
                        result.append(val)
                        i += consumed
                    else:
                        result.append(s[i])
                        i += 1
                if i < len(s):
                    i += 1  # skip closing "
            elif s[i] == "'":
                # Single-quoted section: literal, remove quotes
                i += 1
                while i < len(s) and s[i] != "'":
                    result.append(s[i])
                    i += 1
                if i < len(s):
                    i += 1  # skip closing '
            elif s[i] == '$':
                val, consumed = self._expand_var(s, i)
                result.append(val)
                i += consumed
            else:
                result.append(s[i])
                i += 1
        return ''.join(result)

    def _expand_var(self, s, i):
        """Expand a variable reference starting at position i.

        Returns (expanded_value, chars_consumed).
        """
        if i + 1 >= len(s):
            return ('$', 1)
        if s[i + 1] == '{':
            end = s.find('}', i + 2)
            if end != -1:
                var = s[i + 2:end]
                return (self.env.get(var, ''), end - i + 1)
            return ('${', 2)
        elif s[i + 1] == '?':
            return (self.env.get('?', '0'), 2)
        else:
            j = i + 1
            while j < len(s) and (s[j].isalnum() or s[j] == '_'):
                j += 1
            var = s[i + 1:j]
            if var:
                return (self.env.get(var, ''), j - i)
            return ('$', 1)

    def _tokenize(self, line):
        """Split a line into raw tokens respecting quotes.

        Tokens are returned as-is (with quotes and $var references
        intact). Use _expand_and_unquote() on each token to get the
        final measured form.
        """
        tokens = []
        i = 0
        while i < len(line):
            if line[i].isspace():
                i += 1
                continue
            if line[i] == '{':
                tokens.append('{')
                i += 1
            elif line[i] == '}':
                tokens.append('}')
                i += 1
            elif line[i] == ';':
                tokens.append(';')
                i += 1
            else:
                # Accumulate a word — may contain quotes
                j = i
                while j < len(line) and not line[j].isspace() and line[j] not in ('{', '}', ';'):
                    if line[j] in ('"', "'"):
                        q = line[j]
                        j += 1
                        while j < len(line) and line[j] != q:
                            j += 1
                        if j < len(line):
                            j += 1
                    else:
                        j += 1
                tokens.append(line[i:j])
                i = j
        return tokens

    def _measure_cmd(self, cmd_str):
        """Record a command for PCR 8 measurement."""
        self.commands.append(cmd_str)

    def _eval_test(self, args):
        """Evaluate a [ ... ] test expression.

        Supports: -n, -z, -f, =, !=, -ne, -a (AND), -o (OR).
        In the Flatcar grub.cfg only simple two/three-arg tests
        are used, combined with -a and -o.
        """
        if args and args[-1] == ']':
            args = args[:-1]

        def _single(a):
            if len(a) == 2 and a[0] == '-n':
                return a[1] != ''
            if len(a) == 2 and a[0] == '-z':
                return a[1] == ''
            if len(a) == 2 and a[0] == '-f':
                return a[1] in self.existing_files
            if len(a) == 3 and a[1] == '=':
                return a[0] == a[2]
            if len(a) == 3 and a[1] == '!=':
                return a[0] != a[2]
            if len(a) == 3 and a[1] == '-ne':
                try:
                    return int(a[0]) != int(a[2])
                except ValueError:
                    return True
            return len(a) == 1 and a[0] != ''

        def _split(lst, sep):
            groups, cur = [], []
            for x in lst:
                if x == sep:
                    groups.append(cur); cur = []
                else:
                    cur.append(x)
            groups.append(cur)
            return groups

        return any(
            all(_single(part) for part in _split(group, '-a'))
            for group in _split(args, '-o'))

    def _parse_if_block(self, lines, start):
        """Parse an if/elif/else/fi block starting at 'start'.

        Returns (branches, end_index) where branches is a list of
        (condition_line_or_None, body_lines) tuples.
        """
        branches = []
        depth = 0
        current_cond = lines[start]  # the 'if ...; then' line
        current_body = []

        i = start + 1
        while i < len(lines):
            tokens = self._tokenize(lines[i])
            if not tokens:
                i += 1
                continue
            cmd = tokens[0]

            # Track nested if depth
            if cmd == 'if':
                depth += 1
                current_body.append(lines[i])
            elif cmd == 'fi':
                if depth > 0:
                    depth -= 1
                    current_body.append(lines[i])
                else:
                    branches.append((current_cond, current_body))
                    return branches, i
            elif cmd in ('elif', 'else') and depth == 0:
                branches.append((current_cond, current_body))
                current_cond = lines[i] if cmd == 'elif' else None
                current_body = []
            else:
                current_body.append(lines[i])
            i += 1

        branches.append((current_cond, current_body))
        return branches, i

    def _parse_cond_line(self, line):
        """Extract the test args from 'if [ ... ]; then' or 'elif [ ... ]; then'."""
        tokens = self._tokenize(line)
        # Remove 'if' or 'elif' prefix
        if tokens and tokens[0] in ('if', 'elif'):
            tokens = tokens[1:]
        # Remove trailing '; then' or 'then'
        while tokens and tokens[-1] in ('then', ';'):
            tokens.pop()
        return tokens

    def _execute(self, lines):
        """Execute a list of preprocessed GRUB script lines."""
        i = 0
        # Collect menuentry definitions for deferred execution
        menuentries = []
        while i < len(lines):
            line = lines[i]
            tokens = self._tokenize(line)
            if tokens and tokens[0] == 'menuentry':
                # Collect the menuentry, measure it, but defer body execution
                entry_id = None
                for t in tokens:
                    if t.startswith('--id='):
                        entry_id = t[5:]
                        break
                # Collect body until closing }
                body = []
                j = i + 1
                depth = 1
                while j < len(lines):
                    t2 = self._tokenize(lines[j])
                    for tk in t2:
                        if tk == '{':
                            depth += 1
                        elif tk == '}':
                            depth -= 1
                    if depth == 0:
                        break
                    body.append(lines[j])
                    j += 1

                me_source = self._menuentry_source(self._raw_text, line)
                self._measure_cmd(me_source)

                title = self._expand_and_unquote(tokens[1])
                menuentries.append((entry_id, title, body))
                i = j + 1
            else:
                i = self._execute_line(lines, i)

        # After all lines processed, execute the selected menuentry
        for entry_id, title, body in menuentries:
            if entry_id == self.menuentry:
                self._measure_cmd(f'setparams {title}')
                self._execute(body)
                break

    def _execute_line(self, lines, i):
        """Execute a single line, return next line index."""
        if i >= len(lines):
            return i + 1

        line = lines[i]
        tokens = self._tokenize(line)
        if not tokens:
            return i + 1

        cmd = tokens[0]

        # --- if / elif / else / fi ---
        if cmd == 'if':
            branches, end_i = self._parse_if_block(lines, i)
            for cond_line, body in branches:
                if cond_line is None:
                    # else branch — always taken
                    self._execute(body)
                    break
                test_tokens = self._parse_cond_line(cond_line)
                expanded = [self._expand_and_unquote(t) for t in test_tokens]
                # Measure the test command
                test_str = ' '.join(expanded)
                self._measure_cmd(test_str)
                result = self._eval_test(expanded[1:]) if expanded[0] == '[' else False
                if result:
                    self._execute(body)
                    break
            return end_i + 1

        # --- function definition ---
        if cmd == 'function':
            func_name = tokens[1] if len(tokens) > 1 else ''
            # Collect body until closing }
            body = []
            j = i + 1
            depth = 1
            while j < len(lines):
                t = self._tokenize(lines[j])
                for tk in t:
                    if tk == '{':
                        depth += 1
                    elif tk == '}':
                        depth -= 1
                if depth == 0:
                    break
                body.append(lines[j])
                j += 1
            self.functions[func_name] = body
            return j + 1

        # --- for loops (not normally taken in Flatcar boot) ---
        if cmd == 'for':
            # Skip for loops — the net_default_server branch is
            # not taken in local boot scenarios
            j = i + 1
            depth = 1
            while j < len(lines):
                t = self._tokenize(lines[j])
                if t and t[0] == 'for':
                    depth += 1
                elif t and t[0] == 'done':
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            return j + 1

        # --- regular commands ---
        # Expand each token: quoted tokens stay whole, unquoted ones
        # are subject to word splitting (whitespace in expanded $vars).
        expanded_words = []
        for t in tokens:
            val = self._expand_and_unquote(t)
            if '"' in t or "'" in t:
                if val:
                    expanded_words.append(val)
            else:
                expanded_words.extend(val.split())
        cmd_str = ' '.join(expanded_words)
        self._measure_cmd(cmd_str)
        self._handle_cmd(expanded_words)
        return i + 1

    def _handle_cmd(self, tokens):
        """Handle side effects of a command (variable changes, etc.)."""
        cmd = tokens[0]

        if cmd == 'set' and len(tokens) >= 2:
            # set var=value
            assignment = ' '.join(tokens[1:])
            eq = assignment.find('=')
            if eq != -1:
                var = assignment[:eq]
                val = assignment[eq + 1:]
                self.env[var] = val

        elif cmd == 'search' and '--set' in tokens:
            # search --no-floppy --set oem --part-label OEM --hint ...
            set_idx = tokens.index('--set')
            if set_idx + 1 < len(tokens):
                var = tokens[set_idx + 1]
                if '--part-label' in tokens:
                    pl_idx = tokens.index('--part-label')
                    label = tokens[pl_idx + 1] if pl_idx + 1 < len(tokens) else ''
                    if label == 'OEM' and self.oem_partition:
                        self.env[var] = self.oem_partition
                    # If no OEM partition, var stays unset

        elif cmd == 'source' and len(tokens) >= 2:
            # source (oem)/grub.cfg — measure file in PCR 9
            if self.oem_grub_cfg is not None:
                # Execute the OEM config
                oem_lines = self._preprocess(self.oem_grub_cfg)
                self._execute(oem_lines)

        elif cmd == 'gptprio.next':
            # gptprio.next -d usr_device -u usr_uuid
            if '-u' in tokens:
                u_idx = tokens.index('-u')
                if u_idx + 1 < len(tokens):
                    self.env[tokens[u_idx + 1]] = self.usr_uuid
            if '-d' in tokens:
                d_idx = tokens.index('-d')
                if d_idx + 1 < len(tokens):
                    self.env[tokens[d_idx + 1]] = 'ignored'
            self.env['?'] = '0'

        elif cmd in ('linux', 'linuxefi'):
            # Kernel command line is measured separately in PCR 8
            cmdline = ' '.join(tokens[1:])
            self.kernel_cmdline = cmdline

        # Function calls
        elif cmd in self.functions:
            self._execute(self.functions[cmd])


def evaluate_grub_cfg(grub_cfg, env=None, oem_partition=None,
                      oem_grub_cfg=None, existing_files=None,
                      usr_uuid=None, menuentry='flatcar'):
    """Evaluate a Flatcar grub.cfg and return PCR 8 commands.

    This is the main entry point for the GRUB config evaluator.
    See GrubEvaluator for argument descriptions.

    Returns a list of measured command strings. The kernel command line,
    if produced by the selected menuentry, is appended as the final entry.
    """
    ev = GrubEvaluator(grub_cfg, env=env, oem_partition=oem_partition,
                       oem_grub_cfg=oem_grub_cfg,
                       existing_files=existing_files,
                       usr_uuid=usr_uuid, menuentry=menuentry)
    commands = list(ev.commands)
    if ev.kernel_cmdline:
        commands.append(ev.kernel_cmdline)
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
    for event in data.get('events', []):
        pcr_index = event.get('PCRIndex')
        if pcr_index not in (4, 8, 9):
            continue
        digests = event.get('Digests', [])
        for d in digests:
            if d.get('AlgorithmId') != hash_algo:
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


# Default partition layout values from build_library/disk_layout.json
DEFAULT_OEM_PARTITION = 'hd0,gpt6'        # partition 6 = OEM
DEFAULT_USR_UUID = '7130c94a-213a-4e5a-8e26-6cce9662f132'  # partition 3 = USR-A

# @@MOUNTUSR@@ replacements from build_library/grub_install.sh
MOUNTUSR_VERITY = 'mount.usr=/dev/mapper/usr verity.usr'
MOUNTUSR_PLAIN = 'mount.usr'


def _eval_grub_cfg_from_args(args):
    """Build the evaluated GRUB command list from pcr8-eval CLI args."""
    with open(args.grub_cfg, 'r') as f:
        grub_cfg = f.read()

    # Substitute @@MOUNTUSR@@ if present
    if '@@MOUNTUSR@@' in grub_cfg:
        replacement = MOUNTUSR_VERITY if args.verity else MOUNTUSR_PLAIN
        grub_cfg = grub_cfg.replace('@@MOUNTUSR@@', replacement)

    oem_grub_cfg = None
    if args.oem_grub_cfg:
        with open(args.oem_grub_cfg, 'r') as f:
            oem_grub_cfg = f.read()

    root = args.root
    existing_files = set()
    if args.first_boot:
        existing_files.add(f'({root})/flatcar/first_boot')

    env = {
        'root': root,
        'grub_platform': 'efi',
        'grub_cpu': args.grub_cpu,
    }

    return evaluate_grub_cfg(
        grub_cfg, env=env,
        oem_partition=args.oem_partition,
        oem_grub_cfg=oem_grub_cfg,
        existing_files=existing_files,
        usr_uuid=args.usr_uuid,
        menuentry=args.menuentry)


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
    p4.add_argument('--kernel', help='Path to kernel (vmlinuz-a)')
    p4.add_argument('--no-sb', action='store_true',
                    help='SecureBoot disabled: skip kernel measurement in PCR 4')

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
    pa.add_argument('--no-sb', action='store_true',
                    help='SecureBoot disabled: skip kernel measurement in PCR 4')
    pa.add_argument('--commands-file', required=True,
                    help='File with GRUB commands, one per line')
    pa.add_argument('--oem-grub-cfg', nargs='*', default=[],
                    help='Path(s) to OEM grub.cfg file(s) sourced during boot')

    # pcr8-eval
    p8e = sub.add_parser('pcr8-eval',
                          help='Compute PCR 8 by evaluating grub.cfg')
    p8e.add_argument('--grub-cfg', required=True,
                     help='Path to grub.cfg (@@MOUNTUSR@@ is substituted automatically)')
    p8e.add_argument('--verity', action=argparse.BooleanOptionalAction,
                     default=True,
                     help='Use dm-verity mount.usr (default: --verity)')
    p8e.add_argument('--oem-grub-cfg',
                     help='Path to OEM grub.cfg to source')
    p8e.add_argument('--root', default='hd0,gpt1',
                     help='GRUB root device (default: hd0,gpt1)')
    p8e.add_argument('--grub-cpu', default='x86_64',
                     choices=['x86_64', 'arm64'],
                     help='CPU architecture (default: x86_64)')
    p8e.add_argument('--oem-partition', default=DEFAULT_OEM_PARTITION,
                     help='OEM partition device (default: %(default)s)')
    p8e.add_argument('--usr-uuid', default=DEFAULT_USR_UUID,
                     help='USR partition UUID from gptprio (default: %(default)s)')
    p8e.add_argument('--first-boot', action='store_true',
                     help='Simulate first boot (first_boot file exists)')
    p8e.add_argument('--menuentry', default='flatcar',
                     help='Menuentry --id to boot (default: flatcar)')
    p8e.add_argument('--print-commands', action='store_true',
                     help='Print the evaluated command list instead of PCR')

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
        kernel = None if args.no_sb else args.kernel
        if not args.no_sb and not args.kernel:
            parser.error('pcr4: --kernel is required unless --no-sb is given')
        results['pcr4'] = compute_pcr4(
            args.shim, args.grub, kernel, args.algo)

    elif args.command == 'pcr8':
        commands = load_commands_file(args.commands_file)
        results['pcr8'] = compute_pcr8(commands, args.algo)

    elif args.command == 'pcr8-eval':
        commands = _eval_grub_cfg_from_args(args)
        if args.print_commands:
            for cmd in commands:
                print(cmd.replace('\n', '\\n'))
        else:
            results['pcr8'] = compute_pcr8(commands, args.algo)

    elif args.command == 'pcr9':
        results['pcr9'] = compute_pcr9(
            args.kernel,
            args.oem_grub_cfg if args.oem_grub_cfg else None,
            args.algo)

    elif args.command == 'all':
        kernel_pcr4 = None if args.no_sb else args.kernel
        results['pcr4'] = compute_pcr4(
            args.shim, args.grub, kernel_pcr4, args.algo)
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
