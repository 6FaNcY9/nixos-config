# Implementation Notes for Comprehensive Plan 2025

**Related Documents**:
- [Comprehensive Plan](./COMPREHENSIVE-PLAN-2025.md)
- [Quick Reference](./PLAN-QUICK-REFERENCE.md)
- [Sudo Workaround](./SUDO-OPENCODE-WORKAROUND.md)

---

## 🔧 OpenCode/AI Assistant Workflow Tips

### Using Sudo Commands in OpenCode

Your system has a **`gsudo` workaround** configured for running sudo commands in OpenCode/SSH environments.

**Configuration**:
```nix
# home-modules/shell.nix (line 64)
gsudo = "sudo -A";  # GUI sudo (askpass) - matches GPG pinentry workflow

# nixos-modules/core.nix (lines 149-150)
SUDO_ASKPASS = "${pkgs.openssh-askpass}/libexec/ssh-askpass";
```

**How It Works**:
1. `gsudo` is a Fish shell abbreviation that expands to `sudo -A`
2. The `-A` flag tells sudo to use `SUDO_ASKPASS` (GUI password prompt)
3. A GTK dialog appears (polkit-gnome style) for password entry
4. Works in OpenCode where regular `sudo` fails (no TTY)

**Usage Examples**:
```bash
# Instead of:
sudo nixos-rebuild switch

# Use in OpenCode:
gsudo nixos-rebuild switch

# Other examples:
gsudo systemctl restart some-service
gsudo nix-collect-garbage -d
gsudo nixos-rebuild test
```

**Important**: 
- ✅ Works in OpenCode/SSH environments
- ✅ GUI popup appears for password (like GPG pinentry)
- ⚠️ Popup may briefly interfere with TUI (expected behavior)
- ⚠️ Only works in Fish shell (your default)

**Fallback for NOPASSWD Commands**:
Some commands already work without password (configured in `nixos-modules/core.nix`):
- `nixos-rebuild` 
- `systemctl`
- `nix-store`

For these, you can use either `sudo` or `gsudo` - both work.

---

## 📋 Phase Implementation Helpers

### Phase 5: Testing Infrastructure

**Commands for Testing**:
```bash
# Build tests without running
nix build .#checks.x86_64-linux.system-boot-test

# Run integration test
nix build .#checks.x86_64-linux.desktop-test --print-build-logs

# Run all tests
nix flake check --print-build-logs

# Quick unit test for lib helpers
nix eval .#lib.mkWorkspaceBindings --apply 'x: x { mod = "Mod4"; workspaces = [1 2 3]; commandPrefix = "workspace"; }'
```

**NixOS Test VM**:
```bash
# Build and run test VM
nix build .#nixosConfigurations.bandit.config.system.build.vm
./result/bin/run-bandit-vm

# Interactive test shell
nix build .#checks.x86_64-linux.desktop-test.driver
./result/bin/nixos-test-driver
```

---

### Phase 6: Security Hardening

**AppArmor Commands**:
```bash
# Check AppArmor status
gsudo aa-status

# Load profile
gsudo apparmor_parser -r /etc/apparmor.d/firefox

# Set profile to complain mode (permissive)
gsudo aa-complain /etc/apparmor.d/firefox

# Set profile to enforce mode
gsudo aa-enforce /etc/apparmor.d/firefox

# Check profile logs
gsudo journalctl -xe | grep -i apparmor
```

**USBGuard Commands**:
```bash
# List current USB devices
gsudo usbguard list-devices

# List rules
gsudo usbguard list-rules

# Allow a device permanently
gsudo usbguard allow-device <device-id> --permanent

# Generate rules from current devices
gsudo usbguard generate-policy > /tmp/usbguard-policy.txt
```

**Audit Commands**:
```bash
# Search audit logs
gsudo ausearch -k secrets        # Search by key
gsudo ausearch -f /etc/passwd    # Search by file
gsudo ausearch -ts recent        # Recent events

# Audit reports
gsudo aureport --summary
gsudo aureport --failed
gsudo aureport --executable
```

---

### Phase 7: Multi-Host Support

**Adding a New Host**:
```bash
# 1. Generate hardware config on new machine
nixos-generate-config --show-hardware-config > /tmp/hardware.nix

# 2. Copy to repository
scp new-host:/tmp/hardware.nix nixos-configurations/new-host/

# 3. Create host config
mkdir -p nixos-configurations/new-host
cp nixos-configurations/templates/laptop.nix nixos-configurations/new-host/default.nix

# 4. Edit and customize
nvim nixos-configurations/new-host/default.nix

# 5. Add to flake.nix
nvim flake.nix  # Add to ezConfigs.nixos.hosts

# 6. Generate age key for new host
ssh new-host "ssh-keyscan localhost > /tmp/host-key.pub"
ssh-to-age < /tmp/host-key.pub > secrets/hosts/new-host.age.pub

# 7. Update SOPS config
nvim .sops.yaml  # Add new host key

# 8. Build remotely
nixos-rebuild switch --flake .#new-host --target-host new-host --build-host localhost
```

---

### Phase 8: Backup Enhancements

**Restic Commands**:
```bash
# Initialize Backblaze B2 repository
export B2_ACCOUNT_ID="your-account-id"
export B2_ACCOUNT_KEY="your-account-key"
restic -r b2:bucket-name:/path init

# Manual backup
gsudo systemctl start restic-backups-cloud.service

# Check backup status
gsudo systemctl status restic-backups-cloud.service

# List snapshots
restic -r /mnt/backup/restic snapshots

# Check repository integrity
restic -r /mnt/backup/restic check

# Restore specific file
restic -r /mnt/backup/restic restore latest --target /tmp/restore --include /home/vino/.ssh/config

# Mount snapshot (browse files)
mkdir /tmp/restic-mount
restic -r /mnt/backup/restic mount /tmp/restic-mount
# Browse in another terminal, then:
fusermount -u /tmp/restic-mount
```

**Backup Testing**:
```bash
# Run automated restore test
./tests/backup-restore.sh

# Manual test
restic -r /mnt/backup/restic restore latest --target /tmp/test-restore
diff -r /home/vino/Documents /tmp/test-restore/home/vino/Documents
```

---

### Phase 9: Wayland/Hyprland Migration

**Testing Hyprland**:
```bash
# Install Hyprland (already in config if enabled)
# desktop.wayland.enable = true;

# Test in nested session (without switching)
Hyprland

# Or test in separate VT
# Press Ctrl+Alt+F2
# Login
# startx Hyprland

# Check Wayland session
echo $XDG_SESSION_TYPE  # Should show "wayland"
echo $WAYLAND_DISPLAY   # Should show "wayland-0" or similar

# Test apps
firefox  # Should use Wayland
chromium --enable-features=UseOzonePlatform --ozone-platform=wayland
```

**Hyprland Commands**:
```bash
# Reload config
hyprctl reload

# List windows
hyprctl clients

# List workspaces
hyprctl workspaces

# Execute command
hyprctl dispatch exec alacritty
```

---

### Phase 10: Impermanence

**⚠️ CRITICAL: Backup Before Migration**:
```bash
# 1. Full restic backup
gsudo systemctl start restic-backups-local.service

# 2. BTRFS snapshots
gsudo snapper -c root create --description "Pre-impermanence"
gsudo snapper -c home create --description "Pre-impermanence"

# 3. Export age key (CRITICAL!)
gsudo cp /var/lib/sops-nix/key.txt ~/age-key-backup.txt
# Copy to USB drive or password manager

# 4. List all files in /var/lib (identify what to persist)
find /var/lib -type d | sort > /tmp/var-lib-dirs.txt

# 5. Test in VM first!
nix build .#nixosConfigurations.bandit-impermanence.config.system.build.vm
```

**Impermanence Commands**:
```bash
# Check if root is tmpfs
df -h /
# Should show: tmpfs

# List persistent mounts
findmnt | grep persist

# Check what's persisted
ls -la /persist/

# Create test file to verify ephemeral root
echo "test" | gsudo tee /test-file.txt
# Reboot, file should be gone
```

---

## 🐛 Troubleshooting Common Issues

### "gsudo: command not found"
**Cause**: Not in Fish shell or abbreviations not loaded

**Fix**:
```bash
# Check current shell
echo $SHELL  # Should be /run/current-system/sw/bin/fish

# Reload Fish config
source ~/.config/fish/config.fish

# Or just use sudo -A directly
sudo -A command
```

---

### GUI Popup Doesn't Appear
**Cause**: SUDO_ASKPASS not configured or X11 not available

**Fix**:
```bash
# Check environment variable
echo $SUDO_ASKPASS
# Should show: /nix/store/.../ssh-askpass

# Check X11 display
echo $DISPLAY
# Should show: :0 or :1

# Test askpass directly
$SUDO_ASKPASS "Test password prompt"
# Should show GUI popup
```

---

### Test Builds Fail
**Cause**: Various - check build output

**Fix**:
```bash
# Verbose build
nix build .#checks.x86_64-linux.system-test --print-build-logs

# Check test logs
nix log /nix/store/...-system-test

# Build without tests
nix build .#nixosConfigurations.bandit.config.system.build.toplevel
```

---

### Secrets Don't Decrypt After Impermanence
**Cause**: Age key not persisted

**Fix**:
```bash
# BEFORE enabling impermanence, verify key is persisted
ls -la /persist/var/lib/sops-nix/key.txt

# If missing, copy from backup
gsudo mkdir -p /persist/var/lib/sops-nix
gsudo cp ~/age-key-backup.txt /persist/var/lib/sops-nix/key.txt
gsudo chmod 600 /persist/var/lib/sops-nix/key.txt
```

---

## 📊 Progress Tracking

### Phase Completion Checklist

**Phase 5: Testing** ⬜
- [ ] `tests/` directory created
- [ ] Integration tests written (boot, desktop, services)
- [ ] Unit tests for lib helpers
- [ ] CI workflow runs tests
- [ ] All tests passing

**Phase 6: Security** ⬜
- [ ] AppArmor enabled
- [ ] Firefox profile created and enforcing
- [ ] USBGuard configured with Framework 13 devices
- [ ] Audit logging enabled
- [ ] Firejail sandboxing configured

**Phase 7: Multi-Host** ⬜
- [ ] Host templates created
- [ ] Second host added
- [ ] Per-host secrets configured
- [ ] CI builds all hosts
- [ ] Successfully deployed to second machine

**Phase 8: Backups** ⬜
- [ ] Backblaze B2 account created
- [ ] Cloud backup repository initialized
- [ ] Automated verification running
- [ ] Restore testing passes monthly
- [ ] Monitoring dashboard (if enabled)

**Phase 9: Wayland** ⬜
- [ ] Hyprland installed
- [ ] Keybindings replicate i3 workflow
- [ ] All daily apps tested
- [ ] Screen sharing works
- [ ] Switched to Wayland as primary

**Phase 10: Impermanence** ⬜
- [ ] Full backups completed
- [ ] Age key backed up offline
- [ ] Tested in VM
- [ ] Persistent paths identified
- [ ] Successfully deployed and tested

---

## 🔗 Quick Command Reference

```bash
# Build system
gsudo nixos-rebuild switch --flake .#bandit

# Test without activating
gsudo nixos-rebuild test --flake .#bandit

# Build home manager
home-manager switch --flake .#vino@bandit

# Run tests
nix flake check

# Format code
nix fmt

# Update inputs
nix flake update

# Clean up
gsudo nix-collect-garbage -d

# Check what will be built
nix build .#nixosConfigurations.bandit.config.system.build.toplevel --dry-run
```

---

## 📝 Notes for AI Assistants

When implementing phases from the comprehensive plan:

1. **Always use `gsudo` instead of `sudo`** in OpenCode environment
2. **Check existing documentation** before creating new docs
3. **Test in VM first** for destructive changes (Phases 9, 10)
4. **Create backups** before major changes
5. **Use existing patterns** from the codebase
6. **Follow conventions** in `docs/adding-modules.md`
7. **Update CHANGELOG.md** after completing each phase
8. **Create summary docs** after phase completion

---

**Last Updated**: February 1, 2025  
**Related**: COMPREHENSIVE-PLAN-2025.md, SUDO-OPENCODE-WORKAROUND.md  
**Status**: Ready for Implementation
