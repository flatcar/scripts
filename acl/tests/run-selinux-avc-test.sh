#!/bin/bash
# Test script to validate that SELinux has no denied AVCs.
# This script checks the kernel ring buffer and journal for AVC denial messages
# that could indicate SELinux policy violations.
# Designed to run inside the Azure Container Linux (ACL) VM.

set -euo pipefail

echo "========================================="
echo "SELinux AVC Denial Validation Test"
echo "========================================="
echo ""

# Check if dmesg is available
if ! command -v dmesg &>/dev/null; then
    echo "❌ FAILED: dmesg command not found"
    exit 1
fi

echo "✓ dmesg command is available"

# Capture dmesg output
echo ""
echo "Checking kernel ring buffer for SELinux AVC denials..."

DMESG_OUTPUT=$(dmesg 2>/dev/null || true)

if [ -z "$DMESG_OUTPUT" ]; then
    echo "⚠ WARNING: dmesg returned no output (may need root privileges)"
    echo "Attempting with sudo..."
    DMESG_OUTPUT=$(sudo dmesg 2>/dev/null || true)
    if [ -z "$DMESG_OUTPUT" ]; then
        echo "❌ FAILED: Unable to read dmesg output"
        exit 1
    fi
fi

# Search for AVC denial patterns in dmesg
DMESG_AVC_DENIALS=$(echo "$DMESG_OUTPUT" | grep -E "avc:[[:space:]]+denied" 2>/dev/null || true)

# Also check journalctl for AVC denials
JOURNAL_AVC_DENIALS=""
if command -v journalctl &>/dev/null; then
    echo "Checking journal for SELinux AVC denials..."
    JOURNAL_AVC_DENIALS=$(journalctl --no-pager -q -k 2>/dev/null | grep -E "avc:[[:space:]]+denied" 2>/dev/null || true)
fi

# Final summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="

EXIT_CODE=0

if [ -n "$DMESG_AVC_DENIALS" ]; then
    DENIAL_COUNT=$(echo "$DMESG_AVC_DENIALS" | wc -l)
    echo "❌ AVC denials found in dmesg: $DENIAL_COUNT"
    echo ""
    echo "Denial details (dmesg):"
    echo "-----------------------------"
    echo "$DMESG_AVC_DENIALS"
    echo "-----------------------------"
    EXIT_CODE=1
else
    echo "✅ AVC denials in dmesg: 0"
fi

if [ -n "$JOURNAL_AVC_DENIALS" ]; then
    JOURNAL_COUNT=$(echo "$JOURNAL_AVC_DENIALS" | wc -l)
    echo "❌ AVC denials found in journal: $JOURNAL_COUNT"
    echo ""
    echo "Denial details (journal):"
    echo "-----------------------------"
    echo "$JOURNAL_AVC_DENIALS"
    echo "-----------------------------"
    EXIT_CODE=1
else
    echo "✅ AVC denials in journal: 0"
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ SUCCESS: No SELinux AVC denials detected"
else
    echo "❌ FAILED: SELinux AVC denials detected"
fi

exit $EXIT_CODE
