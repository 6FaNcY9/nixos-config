# USB Backup Testing Guide

## Prerequisites

1. **Clean up old backups** (if not done already):
   ```bash
   ./cleanup-local-backups.sh
   ```

2. **Rebuild system and Home Manager**:
   ```bash
   nh os switch -H bandit
   nh home switch -c vino@bandit
   ```
   
   Or classic rebuild:
   ```bash
   sudo nixos-rebuild switch --flake .#bandit
   home-manager switch --flake .#vino@bandit
   ```

3. **Reload udev rules** (after rebuild):
   ```bash
   sudo udevadm control --reload-rules
   ```

## Testing the USB Backup Flow

### Full Workflow Test (Recommended)

1. **Ensure USB is unplugged** first
2. **Plug in USB** with label "ResticBackup"
3. **Verify automatic behavior**:
   - Floating Alacritty terminal should appear within ~10 seconds
   - Window title: "Backup Progress"
   - Window should be floating, centered, 900×600 pixels
   - Gruvbox-styled prompt asking "Start backup now? [Y/n]"
   - 30-second countdown displayed

4. **Test scenarios**:
   
   **Scenario A: Confirm immediately**
   - Press `Y` or `Enter`
   - Backup should start immediately
   - Real-time logs displayed
   - On completion: success message + "Press any key to close"
   
   **Scenario B: Auto-start on timeout**
   - Don't press anything
   - After 30 seconds: backup auto-starts
   - Same behavior as Scenario A
   
   **Scenario C: Cancel backup**
   - Press `N`
   - Shows "Backup cancelled" message
   - Waits for keypress to close

### Manual Testing (Debugging)

**Test systemd service directly** (without USB insertion):
```bash
# Start the prompt service manually
sudo systemctl start backup-usb-prompt.service

# Check service status
systemctl status backup-usb-prompt.service

# View logs
journalctl -u backup-usb-prompt.service -f
```

**Test backup service independently**:
```bash
# Ensure USB is mounted first
mountpoint /mnt/backup

# Run backup manually
sudo systemctl start restic-backups-home.service

# Follow logs
journalctl -u restic-backups-home.service -f
```

**Monitor udev events**:
```bash
# Watch for USB insertion events
udevadm monitor --environment --udev

# Then plug in USB - should see SYSTEMD_WANTS=backup-usb-prompt.service
```

**Check USB device info**:
```bash
# Find USB device
lsblk -o NAME,LABEL,FSTYPE,SIZE,MOUNTPOINT

# Get detailed udev info
udevadm info --query=all --name=/dev/sdX1 | grep ID_FS_LABEL
```

## Expected Output

### Prompt Screen (Initial)
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Restic Backup System
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Backup USB detected and mounted
  Repository: /mnt/backup/restic
  Backup paths: /home

Start backup now? [Y/n]
(auto-starting in 30 seconds...)
```

### Backup Progress (Sample)
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Starting Backup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Backup mount verified: /dev/sdb1 mounted at /mnt/backup
Starting backup: home
Repository: /mnt/backup/restic
Paths: /home

[... real-time Restic output ...]
Files:       16598 new,   641 changed, 21110 unmodified
Dirs:         3234 new,  6957 changed,     0 unmodified
Added to the repository: 221.275 MiB (66.134 MiB stored)
processed 38349 files, 2.892 GiB in 0:02
snapshot 7de5db9c saved
```

### Completion (Success)
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Backup Completed Successfully
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your data has been safely backed up to the USB drive

Press any key to close...
```

## Troubleshooting

### Terminal Doesn't Appear

**Check udev rule is active**:
```bash
udevadm control --reload-rules
udevadm trigger
```

**Check USB label**:
```bash
lsblk -o NAME,LABEL,FSTYPE
# Should show "ResticBackup" label
```

**Check service status**:
```bash
systemctl status backup-usb-prompt.service
journalctl -u backup-usb-prompt.service -n 50
```

### Terminal Appears But Mount Error

**Verify mount point**:
```bash
mountpoint /mnt/backup
df /mnt/backup
```

**Check fstab entry**:
```bash
cat /etc/fstab | grep ResticBackup
```

**Manually mount**:
```bash
sudo mount /mnt/backup
```

### Backup Fails to Start

**Check Restic service**:
```bash
systemctl status restic-backups-home.service
journalctl -u restic-backups-home.service -n 50
```

**Check repository exists**:
```bash
ls -la /mnt/backup/restic/
```

**Check password file**:
```bash
cat /etc/nixos/restic-password
# Should contain your password
```

### Window Not Floating

**Check i3 configuration**:
```bash
i3-msg -t get_tree | jq '.. | select(.window_properties?.title? == "Backup Progress")'
```

**Reload i3**:
```bash
i3-msg reload
# Or Mod4+Shift+R
```

**Test window rule**:
```bash
alacritty --title "Backup Progress" -e sleep 30
# Should appear floating and centered
```

### X11 Permission Issues

**Check DISPLAY variable**:
```bash
echo $DISPLAY
# Should be :0 or similar
```

**Check Xauthority**:
```bash
ls -la ~/.Xauthority
xauth list
```

**Grant X11 access** (if needed):
```bash
xhost +SI:localuser:root
```

## Configuration Files Modified

- `nixos-modules/backup.nix` - Main backup configuration with USB trigger
- `home-modules/features/desktop/i3/config.nix` - i3 window rules for floating terminal

## Features Implemented

✅ USB auto-detection via udev  
✅ Floating Alacritty terminal (900×600, centered)  
✅ Gruvbox Dark Pale themed UI  
✅ 30-second auto-start timeout  
✅ User confirmation prompt [Y/n]  
✅ Real-time backup progress display  
✅ Wait-for-keypress on completion  
✅ Timer-based backup removed (USB-trigger only)  
✅ Mount verification (prevents internal disk writes)  
✅ Clean error handling and user feedback  

## Notes

- **No automatic timer**: Backups now ONLY run when USB is plugged in
- **Manual trigger**: You can still run `sudo systemctl start restic-backups-home.service` manually
- **Mount safety**: Existing mount verification prevents accidental writes to internal disk
- **Window styling**: Uses Stylix theme automatically via Home Manager
