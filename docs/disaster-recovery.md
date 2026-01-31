# Disaster Recovery Guide

This guide covers how to recover your NixOS system from various disaster scenarios: hardware failures, corrupted system state, accidental deletions, or complete system loss.

---

## Table of Contents

1. [Quick Recovery Checklist](#quick-recovery-checklist)
2. [BTRFS Snapshot Restore](#btrfs-snapshot-restore)
3. [Restic Backup Restore](#restic-backup-restore)
4. [System Rebuild from Scratch](#system-rebuild-from-scratch)
5. [Secrets Recovery](#secrets-recovery)
6. [Emergency Boot Procedures](#emergency-boot-procedures)
7. [Rollback Strategies](#rollback-strategies)
8. [Hardware Failure Scenarios](#hardware-failure-scenarios)
9. [Data Recovery](#data-recovery)
10. [Testing Your Recovery Plan](#testing-your-recovery-plan)

---

## Quick Recovery Checklist

Before disaster strikes, ensure you have:

- [ ] Age key backed up (`/var/lib/sops-nix/key.txt`)
- [ ] SSH keys backed up (`~/.ssh/`)
- [ ] Git configuration repository accessible (GitHub: `6FaNcY9/nixos-config`)
- [ ] Restic password stored securely (outside the system)
- [ ] External backup drive labeled "ResticBackup" with recent snapshots
- [ ] NixOS installation media (USB drive with latest ISO)
- [ ] Hardware configuration backed up (`nixos-configurations/bandit/hardware-configuration.nix`)

**Emergency Contact Info:**
- Repository: `https://github.com/6FaNcY9/nixos-config`
- Backup location: External USB drive (`/mnt/backup/restic`)
- Critical secrets: Age key, Restic password, GitHub SSH key

---

## BTRFS Snapshot Restore

Your system uses BTRFS with Snapper for filesystem snapshots.

### Configuration

- **Snapshots location**: `/.snapshots` (root), `/home/.snapshots` (home)
- **Retention**: 7 daily, 50 total for home
- **Timeline**: Disabled (manual snapshots only)
- **Subvolumes**: `@` (root), `@home` (/home), `@nix` (/nix), `@var` (/var)

### List Available Snapshots

```bash
# List root snapshots
sudo snapper -c root list

# List home snapshots
sudo snapper -c home list
```

### Restore from Snapshot (Live System)

**WARNING**: This will overwrite current files with snapshot versions.

#### Restore Specific Files

```bash
# Find the snapshot number
sudo snapper -c root list

# Browse snapshot contents
sudo ls /.snapshots/42/snapshot/etc/

# Copy files from snapshot
sudo cp /.snapshots/42/snapshot/etc/nixos/configuration.nix /etc/nixos/

# Or for home files
sudo cp /home/.snapshots/15/snapshot/vino/.bashrc /home/vino/
```

#### Restore Entire Subvolume (Emergency)

**DANGER**: This replaces the entire filesystem. Boot from live USB first.

```bash
# Boot from NixOS live USB
# Mount the BTRFS filesystem
sudo mount /dev/nvme0n1p2 /mnt  # Adjust device as needed

# List available snapshots
sudo ls /mnt/@snapshots/

# Delete current subvolume (DESTRUCTIVE)
sudo btrfs subvolume delete /mnt/@

# Restore from snapshot
sudo btrfs subvolume snapshot /mnt/@snapshots/42/snapshot /mnt/@

# Unmount and reboot
sudo umount /mnt
sudo reboot
```

### Manual Snapshot Before Risky Changes

```bash
# Create snapshot with description
sudo snapper -c root create --description "Before kernel update"
sudo snapper -c home create --description "Before config refactor"

# Verify snapshot created
sudo snapper -c root list
```

---

## Restic Backup Restore

Your system backs up `/home` daily to an external USB drive using Restic.

### Configuration

- **Repository**: `/mnt/backup/restic` (external 128GB USB, BTRFS)
- **Schedule**: Daily at 00:03 with 1-hour random delay
- **Retention**: 7 daily, 4 weekly, 6 monthly, 3 yearly
- **Excluded**: `.cache`, `node_modules`, `.direnv`, `target`, `dist`, `build`, `.local/share/Trash`, `.snapshots`
- **Password**: Encrypted in `secrets/restic.yaml`, decrypted to `config.sops.secrets.restic_password.path`

### Prerequisites

1. **Get Restic password**:
   - If system boots: `sudo cat /run/secrets/restic_password`
   - If system dead: Decrypt `secrets/restic.yaml` manually (see [Secrets Recovery](#secrets-recovery))

2. **Mount backup drive**:
   ```bash
   # If not auto-mounted
   sudo mkdir -p /mnt/backup
   sudo mount /dev/disk/by-label/ResticBackup /mnt/backup
   ```

3. **Export password**:
   ```bash
   export RESTIC_REPOSITORY=/mnt/backup/restic
   export RESTIC_PASSWORD_FILE=/run/secrets/restic_password
   # Or manually:
   export RESTIC_PASSWORD="your-decrypted-password"
   ```

### List Available Snapshots

```bash
restic snapshots
```

Example output:
```
ID        Time                 Host        Tags        Paths
-----------------------------------------------------------------
a1b2c3d4  2026-01-31 00:15:23  bandit                  /home
e5f6g7h8  2026-01-30 00:12:45  bandit                  /home
```

### Restore Specific Files/Directories

```bash
# Browse snapshot contents
restic ls a1b2c3d4

# Restore specific directory
restic restore a1b2c3d4 --target /tmp/restore --include /home/vino/Documents

# Restore specific files
restic restore a1b2c3d4 --target /tmp/restore --include /home/vino/.ssh/config
```

### Restore Entire Home Directory

```bash
# Restore to temporary location (safe)
restic restore a1b2c3d4 --target /tmp/restore

# Verify contents
ls -la /tmp/restore/home/vino/

# Copy back to /home (manual merge)
sudo rsync -av /tmp/restore/home/vino/ /home/vino/

# Or restore directly (OVERWRITES existing files)
restic restore a1b2c3d4 --target / --include /home/vino
```

### Restore on New System

```bash
# Install Restic on new system
nix-shell -p restic

# Mount backup drive
sudo mkdir -p /mnt/backup
sudo mount /dev/disk/by-label/ResticBackup /mnt/backup

# Export credentials
export RESTIC_REPOSITORY=/mnt/backup/restic
export RESTIC_PASSWORD="your-password"

# Verify repository
restic snapshots

# Restore (adjust paths as needed)
restic restore latest --target /home/vino
```

### Verify Backup Integrity

```bash
# Quick check (metadata only)
restic check

# Full check with data verification (slow, 5% sampling)
restic check --read-data-subset=5%

# Deep check (reads all data, very slow)
restic check --read-data
```

### Emergency: Recover Restic Password

See [Secrets Recovery](#secrets-recovery) section.

---

## System Rebuild from Scratch

Complete reinstallation guide for catastrophic failures.

### Phase 1: Prepare Installation Media

1. **Download NixOS ISO**:
   - Go to: https://nixos.org/download
   - Get latest minimal ISO (or GNOME ISO for GUI)

2. **Create bootable USB**:
   ```bash
   # On Linux
   sudo dd if=nixos-minimal-XX.XX.iso of=/dev/sdX bs=4M status=progress
   sudo sync

   # On macOS
   sudo dd if=nixos-minimal-XX.XX.iso of=/dev/diskX bs=4m
   ```

3. **Boot from USB**:
   - Framework 13: F12 at boot, select USB
   - Disable Secure Boot if needed (F2 → Security)

### Phase 2: Partition and Format (Fresh Install)

**WARNING**: This destroys all data. Skip if recovering existing partitions.

```bash
# Identify disk
lsblk

# Partition (GPT layout)
sudo parted /dev/nvme0n1 -- mklabel gpt

# Create EFI partition (512MB)
sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/nvme0n1 -- set 1 esp on

# Create root partition (rest of disk)
sudo parted /dev/nvme0n1 -- mkpart primary 512MiB 100%

# Format EFI
sudo mkfs.fat -F 32 -n boot /dev/nvme0n1p1

# Format BTRFS
sudo mkfs.btrfs -L nixos /dev/nvme0n1p2

# Create subvolumes
sudo mount /dev/nvme0n1p2 /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@var
sudo btrfs subvolume create /mnt/@swap
sudo umount /mnt
```

### Phase 3: Mount Filesystems

```bash
# Mount root
sudo mount -o subvol=@,compress=zstd:3,noatime,discard=async /dev/nvme0n1p2 /mnt

# Create mountpoints
sudo mkdir -p /mnt/{boot,home,nix,var,swap}

# Mount subvolumes
sudo mount -o subvol=@home,compress=zstd:3,noatime,discard=async /dev/nvme0n1p2 /mnt/home
sudo mount -o subvol=@nix,compress=zstd:3,noatime,discard=async /dev/nvme0n1p2 /mnt/nix
sudo mount -o subvol=@var,compress=zstd:3,noatime,discard=async /dev/nvme0n1p2 /mnt/var
sudo mount -o subvol=@swap,noatime /dev/nvme0n1p2 /mnt/swap

# Mount boot
sudo mount /dev/nvme0n1p1 /mnt/boot
```

### Phase 4: Create Swapfile (for Hibernate)

```bash
# Create 16GB swapfile (adjust size as needed)
sudo btrfs filesystem mkswapfile --size 16G /mnt/swap/swapfile

# Enable swap
sudo swapon /mnt/swap/swapfile

# Get resume offset (CRITICAL for hibernate)
sudo btrfs inspect-internal map-swapfile -r /mnt/swap/swapfile
# Save this number! You'll need it for boot.kernelParams
```

### Phase 5: Generate Hardware Configuration

```bash
# Generate hardware config
sudo nixos-generate-config --root /mnt

# View generated config
cat /mnt/etc/nixos/hardware-configuration.nix

# Note: You'll replace this with your flake-based config later
```

### Phase 6: Clone Configuration Repository

```bash
# Connect to network (if not auto-connected)
sudo systemctl start wpa_supplicant

# Install git
nix-shell -p git

# Clone your config (read-only, no SSH key yet)
cd /mnt
git clone https://github.com/6FaNcY9/nixos-config.git /mnt/home/vino/nixos-config

# Or if you have SSH key backed up:
# 1. Create ~/.ssh directory
mkdir -p /mnt/home/vino/.ssh
# 2. Copy SSH key from backup
cp /path/to/backup/id_ed25519 /mnt/home/vino/.ssh/
chmod 600 /mnt/home/vino/.ssh/id_ed25519
# 3. Clone via SSH
git clone git@github.com:6FaNcY9/nixos-config.git /mnt/home/vino/nixos-config
```

### Phase 7: Update Hardware Configuration

```bash
# Copy generated hardware config to your repo
sudo cp /mnt/etc/nixos/hardware-configuration.nix \
  /mnt/home/vino/nixos-config/nixos-configurations/bandit/

# Edit bandit config to update resume settings
cd /mnt/home/vino/nixos-config
nano nixos-configurations/bandit/default.nix
```

Update these values in `bandit/default.nix`:

```nix
boot = {
  resumeDevice = "/dev/disk/by-uuid/<your-uuid>";  # From hardware-configuration.nix
  kernelParams = ["resume_offset=<offset>"];       # From btrfs inspect-internal
};
```

### Phase 8: Restore Secrets (CRITICAL)

**Before installation, you need age key and secrets!**

See [Secrets Recovery](#secrets-recovery) section for detailed steps.

Quick version:

```bash
# Restore age key from backup
sudo mkdir -p /mnt/var/lib/sops-nix
sudo cp /path/to/backup/age-key.txt /mnt/var/lib/sops-nix/key.txt
sudo chmod 600 /mnt/var/lib/sops-nix/key.txt

# Verify secrets are encrypted in repo
cd /mnt/home/vino/nixos-config
cat secrets/github.yaml  # Should show encrypted data
cat secrets/restic.yaml
```

### Phase 9: Install NixOS

```bash
cd /mnt/home/vino/nixos-config

# Install with flake
sudo nixos-install --flake .#bandit

# Set root password when prompted
# (You can disable root password later via config)

# Installation will:
# - Build the system configuration
# - Decrypt secrets (using age key)
# - Set up bootloader (GRUB)
# - Create user accounts
```

### Phase 10: Post-Install

```bash
# Reboot into new system
sudo reboot

# After reboot, log in as your user
# Restore home directory from Restic backup (if needed)
export RESTIC_REPOSITORY=/mnt/backup/restic
export RESTIC_PASSWORD="your-password"
restic restore latest --target /home/vino

# Pull latest config changes
cd ~/nixos-config
git pull

# Switch to latest config
nh os switch -H bandit
```

### Phase 11: Verify System

```bash
# Check services
systemctl status

# Verify secrets decrypted
ls -la /run/secrets/

# Test SSH key
ssh -T git@github.com

# Test fingerprint reader (if Framework 13)
fprintd-enroll

# Check backups configured
systemctl status restic-backups-home.timer

# Verify Snapper
sudo snapper -c root list
sudo snapper -c home list
```

---

## Secrets Recovery

Your secrets are encrypted with `sops-nix` using age encryption.

### Understanding the Secret Chain

```
Age Key (/var/lib/sops-nix/key.txt)
  ↓ (decrypts)
Encrypted Secrets (secrets/*.yaml)
  ↓ (decrypts to)
Runtime Secrets (/run/secrets/*)
  ↓ (used by)
Services (GitHub SSH, Restic, etc.)
```

**CRITICAL**: Without the age key, you CANNOT decrypt secrets!

### Backup Age Key (DO THIS NOW)

```bash
# Age key location
sudo cat /var/lib/sops-nix/key.txt

# Backup to secure location (USB drive, password manager, etc.)
sudo cp /var/lib/sops-nix/key.txt ~/age-key-backup.txt
chmod 600 ~/age-key-backup.txt

# Print to paper (emergency backup)
sudo cat /var/lib/sops-nix/key.txt
# Write this down and store securely!
```

**Recommended backups**:
1. **Password manager** (1Password, Bitwarden, KeePass)
2. **USB drive** (encrypted, stored off-site)
3. **Paper backup** (in safe/safety deposit box)
4. **Trusted cloud** (encrypted before upload)

### Restore Age Key

```bash
# On new system (before nixos-install)
sudo mkdir -p /var/lib/sops-nix
sudo cp /path/to/backup/age-key.txt /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt
sudo chown root:root /var/lib/sops-nix/key.txt

# Verify key format (should start with AGE-SECRET-KEY-1)
sudo cat /var/lib/sops-nix/key.txt
```

### Manually Decrypt Secrets (Emergency)

If you need secret values but system won't boot:

```bash
# Install sops
nix-shell -p sops age

# Export age key
export SOPS_AGE_KEY_FILE=/path/to/age-key.txt

# Decrypt secret file
sops -d secrets/restic.yaml
# Output:
# password: your-restic-password

sops -d secrets/github.yaml
# Output:
# github_ssh_key: |
#   -----BEGIN OPENSSH PRIVATE KEY-----
#   ...
```

### Re-encrypt Secrets (New Age Key)

If you lost the age key and need to start fresh:

```bash
# Generate new age key
age-keygen -o new-age-key.txt

# Get public key
age-keygen -y new-age-key.txt
# Output: age1abc123...

# Update .sops.yaml with new public key
nano .sops.yaml
# Replace old key with new one

# Re-encrypt all secrets
sops updatekeys secrets/github.yaml
sops updatekeys secrets/restic.yaml

# Install new age key on system
sudo mkdir -p /var/lib/sops-nix
sudo cp new-age-key.txt /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt

# Rebuild system (will decrypt with new key)
nh os switch
```

**WARNING**: You'll need to manually re-enter secret VALUES (Restic password, SSH key, etc.).

### Secret Rotation Best Practices

```bash
# Rotate secrets periodically (every 6-12 months)
# 1. Generate new secret values (passwords, SSH keys)
# 2. Update encrypted files
sops secrets/restic.yaml  # Edit in place
sops secrets/github.yaml

# 3. Rebuild system
nh os switch

# 4. Update external services (GitHub SSH key, backup repo password)
```

---

## Emergency Boot Procedures

### Boot into Previous Generation

NixOS keeps previous system generations. If current system won't boot:

1. **At GRUB menu**: Press Enter quickly (or it auto-boots)
2. **Select**: "NixOS - <date>" entries (not "Default")
3. **Choose**: Previous working generation
4. **After boot**: 
   ```bash
   # List generations
   sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
   
   # Rollback permanently
   sudo nixos-rebuild switch --rollback
   ```

### GRUB Rescue Mode

If GRUB is broken:

1. **Boot from live USB**
2. **Mount system**:
   ```bash
   sudo mount /dev/nvme0n1p2 -o subvol=@ /mnt
   sudo mount /dev/nvme0n1p1 /mnt/boot
   ```

3. **Chroot**:
   ```bash
   sudo nixos-enter --root /mnt
   ```

4. **Reinstall GRUB**:
   ```bash
   nixos-rebuild switch
   ```

5. **Exit and reboot**:
   ```bash
   exit
   sudo reboot
```

### Live USB Recovery

When system won't boot at all:

```bash
# Boot from NixOS live USB
# Set up networking
sudo systemctl start wpa_supplicant

# Mount system
sudo mount /dev/nvme0n1p2 -o subvol=@ /mnt
sudo mount /dev/nvme0n1p2 -o subvol=@home /mnt/home
sudo mount /dev/nvme0n1p2 -o subvol=@nix /mnt/nix
sudo mount /dev/nvme0n1p1 /mnt/boot

# Chroot into system
sudo nixos-enter --root /mnt

# Now you can:
# - Fix configuration files
# - Rebuild system: nixos-rebuild switch
# - Restore from BTRFS snapshot
# - Check logs: journalctl -xe
```

### Fix Broken Configuration

```bash
# In chroot or booted into old generation
cd /home/vino/nixos-config

# Check git history
git log --oneline -10

# Revert to working commit
git revert <bad-commit>
# Or
git reset --hard <good-commit>

# Rebuild
nixos-rebuild switch --flake .#bandit
```

### Emergency Shell Access

If system boots but GUI won't start:

1. **Switch to TTY**: `Ctrl + Alt + F2`
2. **Login**: username `vino`
3. **Check logs**:
   ```bash
   journalctl -xe
   systemctl status display-manager
   ```
4. **Try switching**: 
   ```bash
   nh os switch
   # Or
   sudo systemctl restart display-manager
   ```

---

## Rollback Strategies

### NixOS Generation Rollback

```bash
# List all generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Rollback to specific generation
sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation 42
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

### Home Manager Rollback

```bash
# List Home Manager generations
home-manager generations

# Activate specific generation
/nix/store/<hash>-home-manager-generation/activate
```

### Git Configuration Rollback

```bash
cd ~/nixos-config

# View history
git log --oneline

# Temporarily test old commit
git checkout <commit-hash>
nh os switch
# If good: keep it
# If bad: git checkout dev

# Permanent revert
git revert <bad-commit>
git push
```

### Flake Input Rollback

```bash
# View flake lock history
git log --oneline flake.lock

# Restore old lock file
git checkout <commit> -- flake.lock

# Rebuild with old inputs
nh os switch
```

---

## Hardware Failure Scenarios

### Disk Failure

**Symptoms**: System won't boot, I/O errors, filesystem corruption

**Recovery**:
1. Boot from live USB
2. Try mounting disk (may fail if severe corruption)
3. If mountable: Copy critical data to external drive
4. If not mountable: Replace disk, reinstall from scratch (see [System Rebuild](#system-rebuild-from-scratch))
5. Restore `/home` from Restic backup

**Prevention**:
- Monitor SMART data: `sudo smartctl -a /dev/nvme0n1`
- Enable BTRFS scrubbing (already configured monthly)
- Keep external backup drive updated

### RAM Failure

**Symptoms**: Random crashes, kernel panics, corrupted data

**Diagnosis**:
```bash
# Boot from live USB
# Run memtest86+ (select from GRUB or use dedicated USB)
```

**Recovery**:
1. Replace faulty RAM
2. System should boot normally (no reinstall needed)
3. Verify system integrity:
   ```bash
   nix-store --verify --check-contents
   sudo btrfs check /dev/nvme0n1p2  # Read-only check
   ```

### Motherboard/CPU Failure

**Recovery**:
1. Replace hardware
2. Boot from live USB
3. If disk is intact: Mount and chroot (see [Live USB Recovery](#live-usb-recovery))
4. Update hardware-configuration.nix if needed
5. Rebuild: `nixos-rebuild switch`

**Note**: NixOS config is hardware-agnostic (mostly). Main changes needed:
- `hardware-configuration.nix` (device names, filesystems)
- Hardware-specific modules (Framework 13 optimizations, etc.)

### Complete Laptop Loss/Theft

**Recovery**:
1. Get new laptop
2. Install NixOS from scratch (see [System Rebuild](#system-rebuild-from-scratch))
3. Clone config from GitHub
4. Restore age key from backup
5. Restore `/home` from most recent off-site backup

**Prevention**:
- Keep age key in password manager (off-device)
- Push config changes to GitHub regularly
- Maintain off-site backup (not just USB drive)
- Consider full disk encryption (LUKS) for sensitive data

---

## Data Recovery

### Critical Files to Backup

**Highest Priority**:
- Age key: `/var/lib/sops-nix/key.txt`
- SSH keys: `~/.ssh/id_*`
- GPG keys: `~/.gnupg/`
- Git repositories: `~/src/*`, `~/nixos-config`

**High Priority**:
- Documents: `~/Documents`
- Photos: `~/Pictures`
- Projects: `~/Projects`, `~/src`
- Configuration: `~/.config` (some apps store important data here)

**Medium Priority**:
- Downloads: `~/Downloads` (ephemeral, but may have recent files)
- Browser data: `~/.mozilla/firefox` (bookmarks, passwords if not using sync)

**Low Priority**:
- Cache: `~/.cache` (can be regenerated)
- Build artifacts: `node_modules`, `target`, `dist` (can be rebuilt)

### Emergency Data Extraction

```bash
# Boot from live USB
# Mount home partition
sudo mount /dev/nvme0n1p2 -o subvol=@home /mnt

# Copy critical files to external drive
sudo cp -r /mnt/vino/.ssh /media/usb/backup/
sudo cp -r /mnt/vino/Documents /media/usb/backup/
sudo cp /mnt/../var/lib/sops-nix/key.txt /media/usb/backup/

# If BTRFS snapshots exist
sudo mount /dev/nvme0n1p2 /mnt2
sudo ls /mnt2/@snapshots/  # Find snapshot
sudo cp -r /mnt2/@snapshots/42/snapshot/home/vino/Documents /media/usb/backup/
```

### Recover Deleted Files

**From BTRFS Snapshot**:
```bash
# List snapshots
sudo snapper -c home list

# Find snapshot before deletion
sudo ls /home/.snapshots/15/snapshot/vino/Documents/

# Restore file
sudo cp /home/.snapshots/15/snapshot/vino/Documents/important.txt ~/Documents/
```

**From Restic Backup**:
```bash
export RESTIC_REPOSITORY=/mnt/backup/restic
export RESTIC_PASSWORD_FILE=/run/secrets/restic_password

# Find file in snapshots
restic find important.txt

# Restore from specific snapshot
restic restore a1b2c3d4 --target /tmp/restore --include important.txt
cp /tmp/restore/home/vino/Documents/important.txt ~/Documents/
```

**From Git** (if file was in repository):
```bash
cd ~/nixos-config

# Find deletion commit
git log --all --full-history -- path/to/deleted/file.nix

# Restore from commit before deletion
git checkout <commit>^ -- path/to/deleted/file.nix
```

---

## Testing Your Recovery Plan

**Don't wait for disaster to test recovery!**

### Monthly Tests

```bash
# 1. Verify BTRFS snapshots exist
sudo snapper -c root list
sudo snapper -c home list

# 2. Verify Restic backups are current
export RESTIC_REPOSITORY=/mnt/backup/restic
export RESTIC_PASSWORD_FILE=/run/secrets/restic_password
restic snapshots | tail -5

# 3. Check backup integrity (quick)
restic check

# 4. Verify age key is backed up
# (Check password manager, USB drive, etc.)
```

### Quarterly Tests

```bash
# 1. Test BTRFS snapshot restore (single file)
sudo cp /home/.snapshots/latest/snapshot/vino/.bashrc /tmp/test-restore
diff /tmp/test-restore ~/.bashrc

# 2. Test Restic restore (single directory)
restic restore latest --target /tmp/restore-test --include /home/vino/Documents/test
diff -r /tmp/restore-test/home/vino/Documents/test ~/Documents/test

# 3. Test generation rollback
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
# Note current generation, boot into previous, boot back

# 4. Test configuration rollback
cd ~/nixos-config
git log --oneline -5
git checkout HEAD~1
nh os test  # Test without activating
git checkout dev
```

### Annual Tests

```bash
# 1. Full Restic integrity check (slow, 30+ minutes)
restic check --read-data

# 2. Test secret decryption
sops -d secrets/restic.yaml
sops -d secrets/github.yaml

# 3. Test live USB boot and system mount
# (Boot from USB, mount system, verify access)

# 4. Verify off-site backups exist and are accessible
```

### Recovery Drill (Simulated Disaster)

**Recommended annually**:

1. **Prepare**:
   - Create VM or use test machine
   - Have age key backup ready
   - Have config repository accessible

2. **Simulate failure**:
   - Attempt fresh install from scratch
   - Restore configuration from git
   - Restore secrets with age key
   - Verify system boots and functions

3. **Document issues**:
   - What was harder than expected?
   - What documentation was missing?
   - What backups were inaccessible?

4. **Update procedures**:
   - Fix gaps in this guide
   - Update backup locations
   - Test new recovery steps

---

## Recovery Time Objectives (RTO)

Estimated time to recover from various scenarios:

| Scenario | RTO | Complexity |
|----------|-----|------------|
| Boot into previous generation | 5 minutes | Low |
| Restore single file from snapshot | 10 minutes | Low |
| Restore directory from Restic | 15 minutes | Low |
| Rollback bad configuration | 20 minutes | Medium |
| Fix broken bootloader | 30 minutes | Medium |
| Restore home directory | 1-2 hours | Medium |
| Full system reinstall (with backups) | 2-4 hours | High |
| Full system reinstall (no backups) | 4-8 hours | High |
| Recovery without age key | Days-Weeks | Very High |

---

## Quick Reference: Recovery Decision Tree

```
System won't boot?
├─ GRUB appears?
│  ├─ YES → Select previous generation
│  └─ NO → Boot live USB, reinstall GRUB
├─ System boots but GUI broken?
│  ├─ YES → Ctrl+Alt+F2, check logs, rollback config
│  └─ NO → See above
└─ Disk not detected?
   └─ Boot live USB, check disk health, replace if needed

File deleted?
├─ Check BTRFS snapshots (instant)
├─ Check Restic backups (minutes)
└─ Check git history (if in repo)

Secrets lost?
├─ Have age key backup? → Decrypt secrets
└─ No age key? → Re-encrypt with new key, manually re-enter values

Hardware failure?
├─ Disk → Replace, reinstall, restore from backup
├─ RAM → Replace, system should boot normally
└─ Motherboard → Replace, update hardware-configuration.nix
```

---

## Emergency Contact Information

**Keep this information accessible outside your system**:

- **Repository**: https://github.com/6FaNcY9/nixos-config
- **Backup Location**: External USB drive labeled "ResticBackup", `/mnt/backup/restic`
- **Age Key**: Backed up in [your password manager/location]
- **Restic Password**: Backed up in [your password manager/location]
- **NixOS ISO**: https://nixos.org/download (latest minimal ISO)
- **This Guide**: https://github.com/6FaNcY9/nixos-config/blob/main/docs/disaster-recovery.md

**Print this page and store with recovery media!**

---

## Additional Resources

- [NixOS Manual - Rollback](https://nixos.org/manual/nixos/stable/#sec-rollback)
- [Restic Documentation](https://restic.readthedocs.io/)
- [BTRFS Wiki - Snapshots](https://btrfs.wiki.kernel.org/index.php/SysadminGuide#Snapshots)
- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [Troubleshooting Guide](./troubleshooting.md) (sister document)

---

**Last Updated**: 2026-01-31  
**System**: Framework 13 AMD (bandit)  
**NixOS Version**: unstable (26.05)
