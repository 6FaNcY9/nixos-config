# Troubleshooting Guide

**NixOS Configuration for Framework 13 AMD (bandit)**  
**Last Updated:** 2026-02-01

This guide covers common issues and solutions for this NixOS configuration.

---

## Quick Diagnostics

```bash
# Check system status
nixos-version
systemctl --failed
journalctl -p err -b

# Check disk space
df -h /nix

# Check recent errors
journalctl -xe

# Verify configuration evaluates
nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath
```

---

## 1. Build Failures

### 1.1 Flake Evaluation Errors

**Error:**
```
error: getting status of '/nix/store/...': No such file or directory
```

**Cause:** Flake inputs haven't been fetched or store path is corrupted.

**Solution:**
```bash
# Update flake inputs
nix flake update

# Clear evaluation cache
rm -rf ~/.cache/nix

# Rebuild
sudo nixos-rebuild switch --flake .#bandit
```

---

**Error:**
```
error: attribute 'X' missing
```

**Cause:** Typo in configuration or missing module import.

**Solution:**
```bash
# Check syntax
nix eval .#nixosConfigurations.bandit --json > /dev/null

# Check module imports
grep -r "imports =" nixos-modules/

# Verify the attribute exists
nix eval .#nixosConfigurations.bandit.config.system.build.toplevel --apply 'x: builtins.attrNames x'
```

---

### 1.2 Missing Inputs/Channels

**Error:**
```
error: cannot find flake 'flake:home-manager' in the flake registries
```

**Cause:** Flake input not defined or misspelled in `flake.nix`.

**Solution:**
```bash
# Check flake.lock exists
ls flake.lock

# Regenerate lock file
rm flake.lock
nix flake lock

# Or update specific input
nix flake lock --update-input home-manager
```

---

### 1.3 Derivation Build Failures

**Error:**
```
error: builder for '/nix/store/...-package-1.0.drv' failed with exit code 1
```

**Cause:** Package build failed (compilation error, missing dependency, etc.)

**Solution:**
```bash
# Try with fallback to stable
# Edit configuration to use pkgs.stable.packageName

# Check build logs
nix log /nix/store/...-package-1.0.drv

# Try building package directly
nix build .#nixosConfigurations.bandit.config.environment.systemPackages --json | jq

# Clear failed builds
nix-store --verify --check-contents --repair
```

---

### 1.4 Cache Issues

**Error:**
```
warning: unable to download '...': HTTP error 404
```

**Cause:** Binary cache unavailable or package not cached.

**Solution:**
```bash
# Verify cache configuration
nix show-config | grep substituters

# Expected:
# substituters = https://cache.nixos.org https://nix-community.cachix.org

# Force rebuild without cache (slower)
sudo nixos-rebuild switch --flake .#bandit --option substitute false

# Or skip single package from cache
nix build --no-substitute .#...
```

---

### 1.5 Out of Disk Space

**Error:**
```
error: while creating directory '/nix/store/...': No space left on device
```

**Cause:** `/nix` partition full.

**Solution:**
```bash
# Check disk usage
df -h /nix
du -sh /nix/store

# Clean old generations (keeps last 3 system + 3 home)
sudo nix-collect-garbage --delete-older-than 7d

# Or aggressive cleanup (keeps current only)
sudo nix-collect-garbage -d

# Optimize store (deduplicate)
nix-store --optimise

# Verify space freed
df -h /nix
```

---

## 2. NixOS Activation Errors

### 2.1 Service Start Failures

**Error:**
```
warning: the following units failed: <service>.service
```

**Solution:**
```bash
# Check service status
systemctl status <service>.service

# View logs
journalctl -u <service>.service -n 50

# Restart service manually
sudo systemctl restart <service>.service

# Disable problematic service temporarily
sudo systemctl stop <service>.service
sudo systemctl disable <service>.service

# Then rebuild
sudo nixos-rebuild switch --flake .#bandit
```

---

### 2.2 Module Conflicts

**Error:**
```
error: The option 'services.X' is defined multiple times
```

**Cause:** Same option set in multiple modules.

**Solution:**
```bash
# Find conflicting definitions
grep -r "services.X.enable" nixos-modules/
grep -r "services.X.enable" nixos-configurations/

# Use lib.mkForce to override
services.X.enable = lib.mkForce true;

# Or lib.mkDefault for lower priority
services.X.enable = lib.mkDefault false;
```

---

### 2.3 Boot Issues

**Problem:** System won't boot after rebuild.

**Solution:**
```bash
# At GRUB menu:
# 1. Select previous generation (older NixOS entries)
# 2. Boot into working system
# 3. Investigate what changed

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or boot specific generation
sudo nixos-rebuild switch --profile-name <generation-number>
```

---

### 2.4 Systemd Service Errors

**Error:**
```
Job for <service>.service failed because the control process exited with error code.
```

**Solution:**
```bash
# Check service definition
systemctl cat <service>.service

# Check for missing dependencies
systemctl list-dependencies <service>.service

# Restart dependency services
sudo systemctl restart <dependency>.service
sudo systemctl restart <service>.service

# Check if enabled
systemctl is-enabled <service>.service

# Enable if needed
sudo systemctl enable --now <service>.service
```

---

## 3. Home Manager Errors

### 3.1 Activation Script Failures

**Error:**
```
Activating <user>
error: collision between '<file1>' and '<file2>'
```

**Cause:** Multiple packages/modules trying to install same file.

**Solution:**
```bash
# Identify conflicting packages
home-manager packages | grep <filename>

# Use home.file.<name>.force = true to override
home.file.".config/some-file".force = true;

# Or remove one of the conflicting packages
```

---

### 3.2 File Conflicts

**Error:**
```
Existing file '<path>' is in the way
```

**Cause:** Manually created file conflicts with Home Manager.

**Solution:**
```bash
# Backup and remove manual file
mv ~/.config/conflicting-file ~/.config/conflicting-file.backup

# Rebuild Home Manager
nh home switch -c vino@bandit

# Or restore from backup if needed
mv ~/.config/conflicting-file.backup ~/.config/conflicting-file
```

---

### 3.3 Program Configuration Errors

**Error:**
```
error: The option 'programs.X.settings.Y' does not exist
```

**Cause:** Option doesn't exist in your Home Manager version.

**Solution:**
```bash
# Check Home Manager manual for correct option
home-manager option programs.X

# Or search in Home Manager source
nix eval nixpkgs#home-manager.options

# Update to unstable if option is new
nix flake lock --update-input home-manager
```

---

### 3.4 Stylix Theme Issues

**Problem:** Colors not applied or theme looks broken.

**Solution:**
```bash
# Verify Stylix is enabled
nix eval .#homeConfigurations.\"vino@bandit\".config.stylix.enable

# Check if palette is loaded
nix eval .#homeConfigurations.\"vino@bandit\".config.stylix.base16Scheme

# Rebuild with verbose output
nh home switch -c vino@bandit --verbose

# Check applied colors
cat ~/.config/i3/config | grep "client.focused"
cat ~/.config/polybar/config.ini | grep "background"
```

---

### 3.5 Font Rendering Problems

**Problem:** Fonts look pixelated or wrong font displayed.

**Solution:**
```bash
# List installed fonts
fc-list | grep "Font Name"

# Rebuild font cache
fc-cache -fv

# Check Stylix font configuration
nix eval .#homeConfigurations.\"vino@bandit\".config.stylix.fonts.monospace.name

# Verify font package installed
nix eval .#homeConfigurations.\"vino@bandit\".config.home.packages --apply 'x: map (p: p.pname) x' | grep font
```

---

## 4. Secrets Management (sops-nix)

### 4.1 Age Key Not Found

**Error:**
```
error: age key not found at '/var/lib/sops-nix/key.txt'
```

**Cause:** Age key not generated yet.

**Solution:**
```bash
# Generate age key
sudo mkdir -p /var/lib/sops-nix
sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
sudo nix-shell -p ssh-to-age --run \
  "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub > /var/lib/sops-nix/key.txt"
sudo chmod 600 /var/lib/sops-nix/key.txt

# Verify key exists
sudo cat /var/lib/sops-nix/key.txt

# Re-encrypt secrets with new key
cd secrets/
sops --config ../.sops.yaml updatekeys github.yaml
sops --config ../.sops.yaml updatekeys restic.yaml
```

---

### 4.2 Decryption Failures

**Error:**
```
Failed to get the data key required to decrypt the SOPS file
```

**Cause:** Secret not encrypted with current age key.

**Solution:**
```bash
# Get current age public key
sudo cat /var/lib/sops-nix/key.txt | grep -v "AGE-SECRET-KEY"
# Or from SSH key
nix-shell -p ssh-to-age --run \
  "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"

# Update .sops.yaml with correct key
# Then re-encrypt
cd secrets/
sops --config ../.sops.yaml updatekeys github.yaml
```

---

### 4.3 Permission Issues

**Error:**
```
error: cannot access '/run/secrets/github_ssh_key': Permission denied
```

**Cause:** Secret has wrong ownership or permissions.

**Solution:**
```bash
# Check secret permissions
ls -la /run/secrets/

# Secrets should be owned by specified user
# Check configuration
nix eval .#nixosConfigurations.bandit.config.sops.secrets.github_ssh_key.owner

# Rebuild to fix permissions
sudo nixos-rebuild switch --flake .#bandit
```

---

### 4.4 Secret Rotation

**Task:** Change a secret value.

**Procedure:**
```bash
cd secrets/

# Edit secret (opens in $EDITOR)
sops github.yaml

# Update the value, save and exit
# SOPS automatically re-encrypts

# Commit and rebuild
git add secrets/github.yaml
git commit -m "chore(secrets): rotate github SSH key"
sudo nixos-rebuild switch --flake .#bandit
```

---

## 5. Flake Update Problems

### 5.1 Lock File Conflicts

**Error:**
```
error: lock file contains changes but is dirty
```

**Cause:** Lock file modified but not committed.

**Solution:**
```bash
# View changes
git diff flake.lock

# Commit changes
git add flake.lock
git commit -m "chore: update flake.lock"

# Or reset to upstream
git checkout origin/main -- flake.lock
```

---

### 5.2 Input Hash Mismatches

**Error:**
```
error: hash mismatch in fixed-output derivation
expected: sha256-...
got:      sha256-...
```

**Cause:** Upstream source changed without version bump.

**Solution:**
```bash
# Update the hash in flake.nix or package definition
# Copy the "got" hash to replace the "expected" hash

# Or let Nix tell you the correct hash
nix build .#packageName 2>&1 | grep "got:"

# Then update the hash in the file
```

---

### 5.3 Dependency Resolution Failures

**Error:**
```
error: cannot resolve dependencies for 'X'
```

**Cause:** Incompatible input versions.

**Solution:**
```bash
# Try updating all inputs
nix flake update

# Or update specific problematic input
nix flake lock --update-input nixpkgs

# Check input compatibility
nix flake metadata

# Use specific commit if needed
inputs.nixpkgs.url = "github:NixOS/nixpkgs/commit-hash";
```

---

### 5.4 Breaking Changes in Unstable

**Problem:** Update breaks configuration.

**Solution:**
```bash
# Check NixOS release notes
# https://nixos.org/manual/nixos/unstable/release-notes

# Use stable fallback for problematic packages
environment.systemPackages = [
  pkgs.stable.problematicPackage
];

# Or pin specific input to working commit
nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/working-commit

# Rollback if needed
sudo nixos-rebuild switch --rollback
```

---

## 6. Hardware-Specific (Framework 13 AMD)

### 6.1 Power-Profiles-Daemon Not Working

**Problem:** Power profiles not switching.

**Solution:**
```bash
# Check service status
systemctl status power-profiles-daemon.service

# List available profiles
powerprofilesctl list

# Manually switch profile
powerprofilesctl set power-saver

# Check current profile
powerprofilesctl get

# Verify amd-pstate driver loaded
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
# Expected: amd-pstate-epp

# Check kernel parameters
cat /proc/cmdline | grep amd
```

---

### 6.2 Fingerprint Reader Issues

**Problem:** Fingerprint authentication not working.

**Solution:**
```bash
# Check service
systemctl status fprintd.service

# List enrolled fingerprints
fprintd-list

# Enroll new fingerprint
fprintd-enroll

# Verify PAM configuration
cat /etc/pam.d/sudo | grep fprintd

# Test fingerprint auth
sudo -v  # Should prompt for fingerprint

# Debugging
journalctl -u fprintd.service -f
```

---

### 6.3 Suspend/Hibernate Problems

**Problem:** System won't suspend or doesn't wake up.

**Solution:**
```bash
# Check suspend mode
cat /sys/power/mem_sleep
# Expected: [s2idle]

# Verify kernel parameters
cat /proc/cmdline | grep mem_sleep

# Test suspend manually
systemctl suspend

# Check wake issues
journalctl -b -1  # Previous boot logs

# Disable problematic USB autosuspend
# Already configured in nixos-modules/roles/laptop.nix

# Check swap for hibernate
sudo swapon --show
cat /proc/swaps
```

---

### 6.4 Battery Threshold Not Applied

**Problem:** Battery charges to 100% despite threshold.

**Note:** Framework 13 AMD battery threshold requires `framework-tool` or EC firmware settings.

**Solution:**
```bash
# Check current charge level
cat /sys/class/power_supply/BAT*/capacity

# Framework battery management is in BIOS
# Reboot and enter BIOS (F2 during boot)
# Look for "Battery Charge Limit" setting

# Or use framework-tool (if available)
nix-shell -p framework-tool --run "framework-tool battery-threshold 80"
```

---

### 6.5 Brightness Control

**Problem:** Brightness keys don't work.

**Solution:**
```bash
# Check backlight devices
ls /sys/class/backlight/

# Test manual brightness change
echo 500 | sudo tee /sys/class/backlight/amdgpu_bl*/brightness

# Verify i3 brightness keybindings
cat ~/.config/i3/config | grep brightness

# Check if light/brightnessctl installed
which light brightnessctl

# Grant user access to backlight
sudo usermod -a -G video vino
# Then re-login
```

---

## 7. Performance Issues

### 7.1 Slow Builds

**Problem:** Nix builds take too long.

**Solution:**
```bash
# Verify binary cache enabled
nix show-config | grep substituters

# Use more cores
sudo nixos-rebuild switch --flake .#bandit --cores 8

# Enable nix-output-monitor
nom build .#nixosConfigurations.bandit.config.system.build.toplevel

# Check network speed
curl -O https://cache.nixos.org/test

# Use local binary cache (cachix)
# Already configured in nixos-modules/core.nix
```

---

### 7.2 High Memory Usage

**Problem:** System using too much RAM during builds.

**Solution:**
```bash
# Check memory usage
free -h
htop

# Reduce parallel jobs
sudo nixos-rebuild switch --flake .#bandit --cores 4 --max-jobs 2

# Increase swap
# Edit nixos-configurations/bandit/default.nix
# Increase swap size or enable zram

# Check zram status
zramctl

# Close heavy applications during build
```

---

### 7.3 Disk Space Problems

**Problem:** Running out of space frequently.

**Solution:**
```bash
# Check store size
du -sh /nix/store

# Aggressive cleanup
sudo nix-collect-garbage -d
nix-collect-garbage -d  # User profile too
sudo nix-store --optimise

# Keep fewer generations
# Edit nixos-modules/core.nix
nix.gc.automatic = true;
nix.gc.dates = "weekly";
nix.gc.options = "--delete-older-than 7d";

# Check for large derivations
du -sh /nix/store/* | sort -h | tail -20
```

---

### 7.4 Network Timeout During Downloads

**Error:**
```
error: unable to download '...': Timeout
```

**Solution:**
```bash
# Increase timeout
sudo nixos-rebuild switch --flake .#bandit --option connect-timeout 300

# Check network
ping cache.nixos.org

# Try different network
# Switch WiFi/Ethernet

# Use alternative mirror
sudo nixos-rebuild switch --flake .#bandit \
  --option substituters "https://mirror.sjtu.edu.cn/nix-channels/store https://cache.nixos.org"
```

---

## 8. Recovery Procedures

### 8.1 Roll Back to Previous Generation

**When:** Current system is broken.

**Procedure:**
```bash
# At GRUB menu: Select older generation

# Or from working shell
sudo nixos-rebuild switch --rollback

# List all generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Switch to specific generation
sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation <number>
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

---

### 8.2 Boot into Recovery Mode

**When:** System won't boot normally.

**Procedure:**
```bash
# Option 1: GRUB menu
# At boot, select "NixOS - Default (recovery mode)"

# Option 2: Single user mode
# At GRUB, press 'e' to edit boot entry
# Add: systemd.unit=emergency.target
# Press Ctrl+X to boot

# Option 3: Live USB
# Boot NixOS live USB
# Mount system and chroot
sudo mount /dev/nvme0n1p2 /mnt
sudo nixos-enter --root /mnt
# Fix configuration
nixos-rebuild switch
```

---

### 8.3 Fix Broken Bootloader

**When:** GRUB not working.

**Procedure:**
```bash
# Boot live USB
# Mount partitions
sudo mount /dev/nvme0n1p2 /mnt
sudo mount /dev/nvme0n1p1 /mnt/boot

# Chroot
sudo nixos-enter --root /mnt

# Reinstall bootloader
nixos-rebuild switch

# Or manually
grub-install /dev/nvme0n1

# Exit and reboot
exit
sudo reboot
```

---

### 8.4 Emergency System Access

**When:** Can't login normally.

**Procedure:**
```bash
# Method 1: Single user mode (see 8.2)

# Method 2: Reset root password
# Boot live USB
sudo mount /dev/nvme0n1p2 /mnt
sudo nixos-enter --root /mnt
passwd root
exit
sudo reboot

# Method 3: SSH from another machine
ssh vino@bandit-ip

# Method 4: TTY
# Press Ctrl+Alt+F2
# Login as root or vino
```

---

## 9. CI/CD Issues

### 9.1 GitHub Actions Failing

**Problem:** CI checks fail on push.

**Solution:**
```bash
# Run checks locally first
nix fmt
nix flake check
nix build .#nixosConfigurations.bandit.config.system.build.toplevel

# View GitHub Actions logs
gh run list
gh run view <run-id> --log

# Check workflow syntax
cat .github/workflows/check.yml

# Test workflow locally (if using act)
act -l
```

---

### 9.2 Flake Check Errors in CI

**Error:** CI fails but local works.

**Cause:** Dirty git tree or local files not committed.

**Solution:**
```bash
# Ensure all files committed
git status
git add .
git commit -m "fix: add missing files"
git push

# CI uses clean clone
# Test with clean build
nix flake check --no-write-lock-file
```

---

## 10. Common Quick Fixes

### Clear All Caches
```bash
rm -rf ~/.cache/nix
sudo rm -rf /nix/var/nix/gcroots/auto/*
nix-collect-garbage -d
sudo nix-collect-garbage -d
```

### Force Rebuild Everything
```bash
sudo nixos-rebuild switch --flake .#bandit --recreate-lock-file
```

### Check Configuration Syntax
```bash
nix eval .#nixosConfigurations.bandit --json > /dev/null
```

### Emergency Disk Space
```bash
# Absolute minimum cleanup
sudo nix-collect-garbage -d
sudo nix-store --optimise
sudo nix-store --gc
```

### Reset Home Manager
```bash
rm -rf ~/.config/home-manager
nh home switch -c vino@bandit
```

---

## Getting Help

### Official Resources
- NixOS Manual: https://nixos.org/manual/nixos/stable/
- NixOS Wiki: https://nixos.wiki/
- Discourse: https://discourse.nixos.org/
- IRC: #nixos on libera.chat

### Debug Commands
```bash
# Verbose rebuild
sudo nixos-rebuild switch --flake .#bandit --show-trace --verbose

# Full evaluation trace
nix eval .#nixosConfigurations.bandit --show-trace

# Build with all output
nix build --print-build-logs --verbose .#nixosConfigurations.bandit.config.system.build.toplevel

# Check dependency tree
nix why-depends /run/current-system <package>
```

---

**For configuration-specific help, see:**
- `docs/architecture.md` - Design decisions
- `docs/disaster-recovery.md` - Emergency procedures
- `docs/adding-modules.md` - Extending configuration
- `README.md` - Configuration overview
