#!/usr/bin/env bash
# Test script for USB backup trigger

set -euo pipefail

echo "=== USB Backup Trigger Test ==="
echo ""

# Step 1: Check if USB is connected
echo "Step 1: Checking if ResticBackup USB is connected..."
if ! lsblk -o NAME,LABEL,FSTYPE,MOUNTPOINT | grep -q "ResticBackup"; then
    echo "❌ ERROR: ResticBackup USB not found"
    echo "Please plug in the USB drive labeled 'ResticBackup'"
    exit 1
fi
echo "✓ USB found"
echo ""

# Step 2: Check udev rule is installed
echo "Step 2: Checking if udev rule is installed..."
if grep -A 1 "ResticBackup" /etc/udev/rules.d/99-local.rules 2>/dev/null | grep -q "backup-usb-prompt"; then
    echo "✓ Udev rule found:"
    grep -A 1 "ResticBackup" /etc/udev/rules.d/99-local.rules | head -3
else
    echo "❌ ERROR: Udev rule not found in /etc/udev/rules.d/99-local.rules"
    echo "You need to rebuild the system:"
    echo "  nh os switch -H bandit"
    exit 1
fi
echo ""

# Step 3: Test manual service trigger
echo "Step 3: Testing manual service trigger..."
echo "This will launch the backup prompt window."
echo "Press Ctrl+C to cancel, or press Enter to continue..."
read

sudo systemctl start backup-usb-prompt.service

echo ""
echo "Service started. Check if Alacritty window appeared."
echo ""

# Step 4: Check service status
echo "Step 4: Checking service status..."
systemctl status backup-usb-prompt.service --no-pager || true
echo ""

# Step 5: View logs
echo "Step 5: Recent service logs:"
journalctl -u backup-usb-prompt.service -n 20 --no-pager
echo ""

echo "=== Test Complete ==="
echo ""
echo "To test full USB insertion flow:"
echo "1. Unplug the USB drive"
echo "2. Run: udevadm monitor --environment --udev"
echo "3. Plug in the USB drive"
echo "4. Watch for the backup-usb-prompt.service to start"
