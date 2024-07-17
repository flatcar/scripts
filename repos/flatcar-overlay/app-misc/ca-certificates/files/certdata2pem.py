#!/usr/bin/python3
# vim:set et sw=4:
#
# certdata2pem.py - splits certdata.txt into multiple files
#
# Copyright (C) 2009 Philipp Kern <pkern@debian.org>
# Copyright (C) 2014 The CoreOS Authors
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
# USA.

import base64
import os.path
import re
import sys
import textwrap

if len(sys.argv) != 3:
    sys.stderr.write("Usage: certdata2pem.py certdata.txt output_dir\n")
    sys.exit(1)

certdata = sys.argv[1]
output_dir = sys.argv[2]
objects = []

# Dirty file parser.
in_data, in_multiline, in_obj = False, False, False
field, field_type, value, obj = None, None, None, dict()
for line in open(certdata, mode='r', encoding='utf8'):
    # Ignore the file header.
    if not in_data:
        if line.startswith('BEGINDATA'):
            in_data = True
        continue
    # Ignore comment lines.
    if line.startswith('#'):
        continue
    # Empty lines are significant if we are inside an object.
    if in_obj and len(line.strip()) == 0:
        objects.append(obj)
        obj = dict()
        in_obj = False
        continue
    if len(line.strip()) == 0:
        continue
    if in_multiline:
        if not line.startswith('END'):
            line = line.strip()
            value += line
            continue
        obj[field] = value
        in_multiline = False
        continue
    if line.startswith('CKA_CLASS'):
        in_obj = True
    line_parts = line.strip().split(' ', 2)
    if len(line_parts) > 2:
        field, field_type = line_parts[0:2]
        value = ' '.join(line_parts[2:])
    elif len(line_parts) == 2:
        field, field_type = line_parts
        value = None
    else:
        raise NotImplementedError('line_parts < 2 not supported.')
    if field_type == 'MULTILINE_OCTAL':
        in_multiline = True
        value = ""
        continue
    obj[field] = value
if len(list(obj.items())) > 0:
    objects.append(obj)

# Build up trust database.
trust = dict()
for obj in objects:
    if obj['CKA_CLASS'] not in ('CKO_NETSCAPE_TRUST', 'CKO_NSS_TRUST'):
        continue
    elif obj['CKA_TRUST_SERVER_AUTH'] in ('CKT_NETSCAPE_TRUSTED_DELEGATOR',
                                          'CKT_NSS_TRUSTED_DELEGATOR'):
        trust[obj['CKA_LABEL']] = True
    elif obj['CKA_TRUST_EMAIL_PROTECTION'] in ('CKT_NETSCAPE_TRUSTED_DELEGATOR',
                                               'CKT_NSS_TRUSTED_DELEGATOR'):
        trust[obj['CKA_LABEL']] = True
    else:
        print("Ignoring certificate %s.  SAUTH=%s, EPROT=%s" % \
              (obj['CKA_LABEL'], obj['CKA_TRUST_SERVER_AUTH'],
               obj['CKA_TRUST_EMAIL_PROTECTION']))

if not os.path.isdir(output_dir):
    os.makedirs(output_dir)
os.chdir(output_dir)

for obj in objects:
    if obj['CKA_CLASS'] == 'CKO_CERTIFICATE':
        if not obj['CKA_LABEL'] in trust or not trust[obj['CKA_LABEL']]:
            continue
        fname = obj['CKA_LABEL'][1:-1].replace('/', '_')\
                                      .replace(' ', '_')\
                                      .replace('(', '=')\
                                      .replace(')', '=')\
                                      .replace(',', '_') + '.pem'
        # fname can be either in utf8 form ("NetLock Arany (Class
        # Gold) Főtanúsítvány") or in an encoded form ("AC Ra\xC3\xADz
        # Certic\xC3\xA1mara S.A.")
        #
        # If fname.encode('latin1') fails, then we assume the first form.
        try:
            # Don't ask, this seems to be the way to convert a string
            # like "T\xc3\x9c\x42\xC4\xB0TAK" into "TÜBİTAK".
            #
            # https://docs.python.org/3/library/codecs.html#text-encodings
            fname = fname.encode('latin1').decode('unicode_escape').encode('latin1').decode('utf8')
        except (UnicodeEncodeError, UnicodeDecodeError):
            pass

        f = open(fname.encode(encoding=sys.getfilesystemencoding(), errors="ignore"), 'w')
        f.write("-----BEGIN CERTIFICATE-----\n")
        # obj['CKA_VALUE'] is a string of octals like '\060\311…',
        # with a number not greater than octal 377 (which is 255,
        # which fits in a byte).
        match_to_int = lambda match: int(match.group(1), 8)
        raw = bytes(map(match_to_int, re.finditer(r'\\([0-3][0-7][0-7])', obj['CKA_VALUE'])))
        f.write("\n".join(textwrap.wrap(base64.b64encode(raw).decode('utf8'), 64)))
        f.write("\n-----END CERTIFICATE-----\n")
