#!/usr/bin/env bash
# Test the new notification-based backup system

set -euo pipefail

echo "=== USB Backup Notification Test ==="
echo ""

# Check if USB is connected
echo "Step 1: Checking if ResticBackup USB is connected..."
if ! lsblk -o LABEL,MOUNTPOINT | grep -q "ResticBackup"; then
    echo "❌ ERROR: ResticBackup USB not found"
    echo "Please plug in the USB drive labeled 'ResticBackup'"
    exit 1
fi
echo "✓ USB found"
echo ""

# Check udev rule
echo "Step 2: Checking if udev rule is installed..."
if grep -A 1 "ResticBackup" /etc/udev/rules.d/99-local.rules 2>/dev/null | grep -q "backup-usb-notify"; then
    echo "✓ Udev rule found"
else
    echo "❌ ERROR: Udev rule not found"
    echo "You need to rebuild: nh os switch -H bandit"
    exit 1
fi
echo ""

# Check if backup-usb command exists
echo "Step 3: Checking if backup-usb command is available..."
if command -v backup-usb &> /dev/null; then
    echo "✓ backup-usb command found"
else
    echo "❌ ERROR: backup-usb command not found"
    echo "You need to rebuild: nh os switch -H bandit"
    exit 1
fi
echo ""

# Test notification service manually
echo "Step 4: Testing notification service..."
echo "This will send a desktop notification."
echo ""

sudo systemctl start backup-usb-notify.service

echo "✓ Service triggered"
echo ""
echo "Did you see a notification appear? (It should say 'Backup USB Detected')"
echo ""
echo "To start the backup, either:"
echo "  1. Click the notification (if your notification daemon supports it)"
echo "  2. Run: backup-usb"
echo ""
