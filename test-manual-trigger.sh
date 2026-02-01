#!/usr/bin/env bash
# Manual trigger test for backup USB prompt

set -euo pipefail

echo "=== Manual Backup Prompt Test ==="
echo ""

# Check if USB is mounted
if ! lsblk -o LABEL,MOUNTPOINT | grep -q "ResticBackup"; then
    echo "⚠ Warning: USB not mounted, attempting to mount..."
    if mountpoint -q /mnt/backup; then
        echo "✓ Already mounted at /mnt/backup"
    else
        sudo mount /mnt/backup 2>/dev/null || {
            echo "❌ Failed to mount. Is the USB plugged in?"
            exit 1
        }
        echo "✓ Mounted successfully"
    fi
else
    echo "✓ USB is mounted"
fi

echo ""
echo "Triggering backup prompt service manually..."
echo ""

sudo systemctl start backup-usb-prompt.service

echo ""
echo "Check if Alacritty window appeared."
echo ""
echo "To view logs:"
echo "  journalctl -u backup-usb-prompt.service -f"
