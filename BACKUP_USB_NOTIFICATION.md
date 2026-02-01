# USB Backup System - New Notification-Based Approach

## Architecture Change

**Problem**: Launching GUI applications (Alacritty) directly from systemd system services is unreliable due to session/permission issues.

**Solution**: Use desktop notifications instead:

1. **USB inserted** → udev triggers `backup-usb-notify.service`
2. **Service sends notification** → "Backup USB Detected - Click to start backup"
3. **User clicks or runs command** → Alacritty terminal opens with backup UI

## How It Works

```
USB Plugged In
     ↓
udev rule detects "ResticBackup" label
     ↓
Triggers: backup-usb-notify.service
     ↓
Sends desktop notification to user
     ↓
User clicks notification OR runs: backup-usb
     ↓
Alacritty opens with backup prompt
     ↓
User confirms or waits 30s
     ↓
Backup runs with real-time progress
```

## Setup

### 1. Rebuild System

```bash
nh os switch -H bandit
```

### 2. Test Notification

```bash
./test-usb-notification.sh
```

This will:
- Check USB is connected
- Verify udev rule is installed
- Verify `backup-usb` command exists
- Send a test notification

### 3. Test Full Flow

**Automatic (USB hotplug)**:
```bash
# Unplug USB
# Plug it back in
# You should see a notification appear
# Click it or run: backup-usb
```

**Manual**:
```bash
backup-usb
```

## Components

### Files Modified

- `nixos-modules/backup.nix`:
  - `backupPromptScript`: The interactive backup UI (unchanged)
  - `backupLauncherScript`: NEW - Wrapper that launches Alacritty
  - `backup-usb-notify.service`: NEW - Sends notification instead of launching GUI
  - Added `backup-usb` command to system packages

### New Services

**`backup-usb-notify.service`**:
- Triggered by udev when USB is inserted
- Mounts `/mnt/backup` if needed
- Sends desktop notification via `notify-send`
- Runs successfully without GUI issues

### New Command

**`backup-usb`**:
- Available system-wide
- Launches the full backup UI in Alacritty
- Can be run manually anytime
- Can be triggered from notification click (if notification daemon supports it)

## Usage

### Automatic Backup on USB Insert

1. Plug in USB labeled "ResticBackup"
2. Wait for notification to appear
3. Click notification or run `backup-usb`
4. Follow prompts in terminal

### Manual Backup

```bash
# Ensure USB is plugged in and mounted
backup-usb
```

## Troubleshooting

### No Notification Appears

Check service status:
```bash
journalctl -u backup-usb-notify.service -n 20
```

Test manually:
```bash
sudo systemctl start backup-usb-notify.service
```

### USB Not Auto-Mounting

Check if mount succeeds:
```bash
sudo systemctl start mnt-backup.mount
mountpoint /mnt/backup
```

### Notification Appears But Can't Click

Some notification daemons don't support clickable actions. Just run:
```bash
backup-usb
```

### Check If Udev Rule Is Working

Monitor udev events:
```bash
udevadm monitor --environment --udev | grep -A 10 "ResticBackup"
```

Then unplug and replug USB.

## Advantages Over Previous Approach

✅ **Reliable**: Notifications work from system services  
✅ **User Control**: User decides when to start backup  
✅ **Standard Pattern**: Uses desktop notification system  
✅ **Fallback**: Can always run `backup-usb` manually  
✅ **Simple**: No complex session/permission juggling  
✅ **Debuggable**: Clear separation of concerns  

## Files

- `nixos-modules/backup.nix` - Main configuration
- `test-usb-notification.sh` - Test script
- `BACKUP_USB_NOTIFICATION.md` - This file

## Next Steps

If this works well, you could enhance it with:
- Make notification clickable (requires notification daemon support)
- Add notification icon/urgency levels
- Add option to auto-start backup without prompt
- Add notification on backup completion
