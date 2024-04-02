#!/bin/bash
# Copyright 2020 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Disables ssh.
systemctl stop sshd.service
systemctl mask sshd.service
systemctl -q is-active sshd.service
IS_ACTIVE=$?
IS_ENABLED=$(systemctl is-enabled sshd.service)

if [[ "$IS_ACTIVE" -eq 0 ]] || [[ "$IS_ENABLED" != "masked" ]]; then
   echo "Failed to disable sshd.service"
   exit 1
else
   echo "sshd.service is disabled"
fi
