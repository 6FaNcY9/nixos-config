#!/usr/bin/env bash
# Cleanup script for removing local backups and preparing USB drive
# Run this after the configuration change is applied

set -e

echo "========================================"
echo "Backup Migration: Internal → USB Drive"
echo "========================================"
echo

# Step 1: Check current backup location
echo "[1/5] Checking current backup status..."
BACKUP_SIZE=$(sudo du -sh /mnt/backup/restic 2>/dev/null | cut -f1 || echo "0")
echo "  Current backup size on internal disk: $BACKUP_SIZE"
echo

# Step 2: Confirm removal
echo "[2/5] Ready to remove local backups"
echo "  ⚠️  WARNING: This will DELETE backups from your internal disk"
echo "  ✓  This is safe because these backups are on the same disk as your data"
echo "  ✓  You'll create new backups on external USB after this"
echo
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi
echo

# Step 3: Remove local backups
echo "[3/5] Removing backups from internal disk..."
sudo rm -rf /mnt/backup/restic
echo "  ✓ Local backups removed"
echo

# Step 4: Check for USB drive
echo "[4/5] Checking for USB drive labeled 'ResticBackup'..."
if lsblk -o LABEL | grep -q "ResticBackup"; then
    USB_DEV=$(lsblk -o NAME,LABEL | grep "ResticBackup" | awk '{print $1}')
    echo "  ✓ Found USB drive: $USB_DEV"
    
    # Check if already mounted
    if mount | grep -q "/mnt/backup"; then
        echo "  ✓ USB already mounted at /mnt/backup"
    else
        echo "  Mounting USB drive..."
        sudo mount /dev/disk/by-label/ResticBackup /mnt/backup
        echo "  ✓ USB mounted successfully"
    fi
else
    echo "  ⚠️  USB drive 'ResticBackup' not found"
    echo
    echo "NEXT STEPS:"
    echo "1. Plug in your 128GB USB drive"
    echo "2. Format it as BTRFS with label 'ResticBackup':"
    echo "   sudo mkfs.btrfs -f -L ResticBackup /dev/sdX1  # Replace sdX1 with your USB device"
    echo "3. Re-run this script"
    exit 1
fi
echo

# Step 5: Verify setup
echo "[5/5] Verifying backup configuration..."
MOUNT_POINT=$(df /mnt/backup | tail -1 | awk '{print $1}')
if echo "$MOUNT_POINT" | grep -q "nvme"; then
    echo "  ✗ ERROR: /mnt/backup is still on internal disk!"
    echo "  This should not happen. Please check USB mount."
    exit 1
else
    echo "  ✓ /mnt/backup is on external device: $MOUNT_POINT"
fi
echo

echo "========================================"
echo "✓ Migration Complete!"
echo "========================================"
echo
echo "NEXT STEPS:"
echo "1. Rebuild system: nh os switch -H bandit"
echo "2. Run first backup: sudo systemctl start restic-backups-home.service"
echo "3. Watch progress: journalctl -u restic-backups-home.service -f"
echo
echo "IMPORTANT:"
echo "- System boots fine WITHOUT USB (nofail mount)"
echo "- Backups ONLY run when USB is actually mounted"
echo "- If USB is missing, backup fails safely with error (no internal disk writes)"
echo "- Daily backups run automatically at 00:03-01:03 (if USB connected)"
echo
echo "TIP: Leave USB plugged in for automatic nightly backups"
