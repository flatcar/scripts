#!/usr/bin/python3

# document has a header and an empty-line-separated list of package groups

# header is a list of all lines until the first package group

# package group has a category name, a list of subgroups and a list of next-pseudogroups

# subgroup is either a list of sorted package names or a list of comments

# next-pseudogroup is a list of comments that comes after the package group

import re
import sys

class FreeForm:
    def __init__(self, lines):
        self.lines = lines

class Pkg:
    def __init__(self, idx, name, out):
        self.free_form_idx = idx
        self.name = name
        self.commented_out = out

class Group:
    def __init__(self):
        self.pkgs = []

class Document:
    def __init__(self):
        self.header = []
        self.free_forms = []
        self.groups = {}

class Reader:
    category_or_pkg_pattern = re.compile("^[a-z0-9-]+(?:/[A-Za-z0-9-_+]+)?$")
    parsing_header = 1
    parsing_group = 2
    parsing_comment = 3

    def __init__(self, doc):
        self.doc = doc
        self.parsing_stage = Reader.parsing_header
        self.current_comments = []
        self.free_form_idx_for_next_pkg = None

    def get_group(self, category):
        if category not in self.doc.groups:
            new_group = Group()
            self.doc.groups[category] = new_group
            return new_group
        return self.doc.groups[category]

    def add_pkg_impl(self, idx, name, out):
        category = name.split('/', 1)[0]
        group = self.get_group(category)
        group.pkgs += [Pkg(idx, name, out)]

    def add_pkg(self, name):
        self.add_pkg_impl(self.free_form_idx_for_next_pkg, name, False)
        self.free_form_idx_for_next_pkg = None

    class CommentBatch:
        def __init__(self, ff_lines, p_lines):
            self.free_form_lines = ff_lines
            self.pkg_lines = p_lines

    def get_batches(self):
        batches = []
        free_form_lines = []
        pkg_lines = []
        for line in self.current_comments:
            line = line.lstrip('#').strip()
            if not line:
                if not pkg_lines:
                    free_form_lines += [line]
            elif Reader.category_or_pkg_pattern.match(line):
                pkg_lines += [line]
            else:
                if pkg_lines:
                    while not free_form_lines[-1]:
                        free_form_lines = free_form_lines[:-1]
                    batches += [Reader.CommentBatch(free_form_lines, pkg_lines)]
                    free_form_lines = []
                    pkg_lines = []
                free_form_lines += [line]
        self.current_comments = []
        if free_form_lines or pkg_lines:
            batches += [Reader.CommentBatch(free_form_lines, pkg_lines)]
        return batches

    def process_current_comments(self):
        for batch in self.get_batches():
            free_form_idx = None
            if batch.free_form_lines:
                free_form_idx = len(self.doc.free_forms)
                self.doc.free_forms += [FreeForm(batch.free_form_lines)]
            if batch.pkg_lines:
                for line in batch.pkg_lines:
                    self.add_pkg_impl(free_form_idx, line, True)
            else:
                self.free_form_idx_for_next_pkg = free_form_idx

    def read(self, input):
        while line := input.readline():
            line = line.strip()
            if self.parsing_stage == Reader.parsing_header:
                if not line:
                    self.parsing_stage = Reader.parsing_group
                elif line.startswith('#'):
                    self.doc.header += [line]
                else:
                    self.parsing_stage = Reader.parsing_group
                    self.add_pkg(line)
            elif self.parsing_stage == Reader.parsing_group:
                if not line:
                    pass
                elif line.startswith('#'):
                    self.current_comments += [line]
                    self.parsing_stage = Reader.parsing_comment
                else:
                    self.add_pkg(line)
            elif self.parsing_stage == Reader.parsing_comment:
                if not line:
                    self.process_current_comments()
                elif line.startswith('#'):
                    self.current_comments += [line]
                else:
                    self.process_current_comments()
                    self.add_pkg(line)
        if self.current_comments:
            self.process_current_comments()

class Writer:
    def __init__(self, doc):
        self.doc = doc

    def write(self, output):
        output_lines = []
        if self.doc.header:
            output_lines += self.doc.header
            output_lines += ['']
        for category in sorted(self.doc.groups):
            last_free_form_idx = None
            for pkg in sorted(self.doc.groups[category].pkgs, key=lambda pkg: pkg.name):
                if pkg.free_form_idx != last_free_form_idx:
                    last_free_form_idx = pkg.free_form_idx
                    if pkg.free_form_idx is not None:
                        for line in self.doc.free_forms[pkg.free_form_idx].lines:
                            if line:
                                output_lines += [f"# {line}"]
                            else:
                                output_lines += ['#']
                if pkg.commented_out:
                    output_lines += [f"# {pkg.name}"]
                else:
                    output_lines += [f"{pkg.name}"]
            output_lines += ['']
        while not output_lines[0]:
            output_lines = output_lines[1:]
        while not output_lines[-1]:
            output_lines = output_lines[:-1]
        for line in output_lines:
            print(line, file=output)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"1 argument expected, got {len(sys.argv) - 1}", file=sys.stderr)
        sys.exit(1)
    filename = sys.argv[1]
    doc = Document()
    with open(filename, 'r', encoding='UTF-8') as file:
        reader = Reader(doc)
        reader.read(file)
    writer = Writer(doc)
    writer.write(sys.stdout)
