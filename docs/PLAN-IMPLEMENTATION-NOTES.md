# Implementation Notes for Comprehensive Plan 2025

**Related Documents**:
- [Comprehensive Plan](./COMPREHENSIVE-PLAN-2025.md)
- [Quick Reference](./PLAN-QUICK-REFERENCE.md)

---

## 🔧 OpenCode/AI Assistant Workflow Tips

### Using Sudo Commands in OpenCode

- Standard sudo behavior only (no askpass/NOPASSWD overrides).
- Use regular `sudo` with a TTY when needed.

---

## 📋 Phase Implementation Helpers

### Phase 5: Testing Infrastructure (Deferred)

- No test infrastructure is planned or needed at this time.
- Do not create a `tests/` directory unless explicitly requested.

---

### Phase 6: Security Hardening

**AppArmor Commands**:
```bash
# Check AppArmor status
sudo aa-status

# Load profile
sudo apparmor_parser -r /etc/apparmor.d/firefox

# Set profile to complain mode (permissive)
sudo aa-complain /etc/apparmor.d/firefox

# Set profile to enforce mode
sudo aa-enforce /etc/apparmor.d/firefox

# Check profile logs
sudo journalctl -xe | grep -i apparmor
```

**USBGuard Commands**:
```bash
# List current USB devices
sudo usbguard list-devices

# List rules
sudo usbguard list-rules

# Allow a device permanently
sudo usbguard allow-device <device-id> --permanent

# Generate rules from current devices
sudo usbguard generate-policy > /tmp/usbguard-policy.txt
```

**Audit Commands**:
```bash
# Search audit logs
sudo ausearch -k secrets        # Search by key
sudo ausearch -f /etc/passwd    # Search by file
sudo ausearch -ts recent        # Recent events

# Audit reports
sudo aureport --summary
sudo aureport --failed
sudo aureport --executable
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
sudo systemctl start restic-backups-cloud.service

# Check backup status
sudo systemctl status restic-backups-cloud.service

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
sudo systemctl start restic-backups-local.service

# 2. BTRFS snapshots
sudo snapper -c root create --description "Pre-impermanence"
sudo snapper -c home create --description "Pre-impermanence"

# 3. Export age key (CRITICAL!)
sudo cp /var/lib/sops-nix/key.txt ~/age-key-backup.txt
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
echo "test" | sudo tee /test-file.txt
# Reboot, file should be gone
```

---

## 🐛 Troubleshooting Common Issues

### Builds Fail
**Cause**: Various - check build output

**Fix**:
```bash
# Build system with logs
nix build .#nixosConfigurations.bandit.config.system.build.toplevel --print-build-logs

# Check flake evaluations
nix flake check
```

---

### Secrets Don't Decrypt After Impermanence
**Cause**: Age key not persisted

**Fix**:
```bash
# BEFORE enabling impermanence, verify key is persisted
ls -la /persist/var/lib/sops-nix/key.txt

# If missing, copy from backup
sudo mkdir -p /persist/var/lib/sops-nix
sudo cp ~/age-key-backup.txt /persist/var/lib/sops-nix/key.txt
sudo chmod 600 /persist/var/lib/sops-nix/key.txt
```

---

## 📊 Progress Tracking

### Phase Completion Checklist

**Phase 5: Testing (Deferred)** ⬜
- [ ] Deferred (no tests directory planned)

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
sudo nixos-rebuild switch --flake .#bandit

# Test without activating
sudo nixos-rebuild test --flake .#bandit

# Build home manager
home-manager switch --flake .#vino@bandit

# Run tests
nix flake check

# Format code
nix fmt

# Update inputs
nix flake update

# Clean up
sudo nix-collect-garbage -d

# Check what will be built
nix build .#nixosConfigurations.bandit.config.system.build.toplevel --dry-run
```

---

## 📝 Notes for AI Assistants

When implementing phases from the comprehensive plan:

1. **Use standard `sudo` (no askpass overrides)**
2. **Check existing documentation** before creating new docs
3. **Test in VM first** for destructive changes (Phases 9, 10)
4. **Create backups** before major changes
5. **Use existing patterns** from the codebase
6. **Follow conventions** in `docs/adding-modules.md`
7. **Update CHANGELOG.md** after completing each phase
8. **Create summary docs** after phase completion

---

**Last Updated**: February 1, 2025  
**Related**: COMPREHENSIVE-PLAN-2025.md
**Status**: Ready for Implementation
