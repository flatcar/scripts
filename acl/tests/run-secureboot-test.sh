#!/bin/bash
# Test script to validate Secure Boot is enabled.
# This script is designed to run inside the Azure Container Linux (ACL) VM.

set -euo pipefail

echo "========================================="
echo "Secure Boot Validation Test"
echo "========================================="
echo ""

# Check if running in EFI mode
if [ ! -d /sys/firmware/efi ]; then
    echo "❌ FAILED: System is not booted in EFI mode"
    echo "   /sys/firmware/efi directory does not exist"
    exit 1
fi

echo "✓ System is booted in EFI mode"

# Check for SecureBoot variable
SECUREBOOT_VAR=$(find /sys/firmware/efi/efivars -name 'SecureBoot-*' 2>/dev/null | head -1)

if [ -z "$SECUREBOOT_VAR" ]; then
    echo "❌ FAILED: SecureBoot EFI variable not found"
    echo "   Available variables:"
    ls -1 /sys/firmware/efi/efivars | grep -i secure || echo "   (none found)"
    exit 1
fi

echo "✓ SecureBoot EFI variable found: $SECUREBOOT_VAR"

# Read SecureBoot status (last byte indicates enabled/disabled)
SECUREBOOT_STATUS=$(cat "$SECUREBOOT_VAR" 2>/dev/null | od -An -t u1 | awk '{print $NF}')

if [ -z "$SECUREBOOT_STATUS" ]; then
    echo "❌ FAILED: Unable to read SecureBoot status"
    exit 1
fi

echo ""
echo "SecureBoot Status Value: $SECUREBOOT_STATUS"
echo ""

if [ "$SECUREBOOT_STATUS" = "1" ]; then
    echo "✅ SUCCESS: Secure Boot is ENABLED"
    exit 0
elif [ "$SECUREBOOT_STATUS" = "0" ]; then
    echo "❌ FAILED: Secure Boot is DISABLED"
    exit 1
else
    echo "❌ FAILED: Unexpected SecureBoot status value: $SECUREBOOT_STATUS"
    exit 1
fi
