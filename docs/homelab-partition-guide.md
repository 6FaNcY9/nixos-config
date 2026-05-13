# Homelab: Partition & Installation Guide

Resize Windows from 4 TB to 1 TB, encrypt the remaining 3 TB with LUKS2,
format it as BTRFS, and install NixOS.

---

## Target partition layout

| # | Size | Type | Purpose |
|---|------|------|---------|
| nvme0n1p1 | ~600 MB | NTFS | Windows Recovery (existing, leave untouched) |
| nvme0n1p2 | ~100 MB | FAT32 | Windows EFI (existing, leave untouched) |
| nvme0n1p3 | ~1 TB | NTFS | Windows 11 C: (shrunk from 4 TB) |
| nvme0n1p4 | 512 MB | FAT32 | NixOS EFI (new) |
| nvme0n1p5 | ~3 TB | LUKS2 → BTRFS | NixOS (new) |

---

## Part 1 — Shrink Windows to 1 TB (do this from inside Windows)

### 1.1 Free up space at the end of the partition

Windows cannot shrink past unmovable files (hibernation file, pagefile, VSS
snapshots). Clear them first.

Open **PowerShell as Administrator**:

```powershell
# Disable hibernation (removes hiberfil.sys, ~several GB at the end of C:)
powercfg /h off

# Disable the pagefile temporarily
# Open: System Properties → Advanced → Performance → Settings → Advanced → Virtual Memory
# Set to "No paging file" on C:, click Set, then OK. Reboot when prompted.
```

After rebooting (still in Windows):

```powershell
# Disable System Restore / VSS snapshots on C: to allow deeper shrink
Disable-ComputerRestore -Drive "C:\"

# Optional: defragment to consolidate free space (not needed on SSD but helps Windows locate boundaries)
# Optimize-Volume -DriveLetter C -Defrag -Verbose
```

### 1.2 Shrink the partition

Open **Disk Management** (`diskmgmt.msc`):

1. Right-click the **C:** volume → **Shrink Volume**
2. In "Enter the amount of space to shrink in MB", enter `3072000` (≈ 3 TB)
   - If Windows limits the shrink to less than 3 TB, use the PowerShell method below
3. Click **Shrink**

**PowerShell alternative** (if Disk Management won't shrink far enough):

```powershell
# Get the current partition size and maximum shrink amount
Get-Partition -DriveLetter C | Select-Object -Property Size, SizeRemaining

# Shrink to 1 TB (1,073,741,824,000 bytes = 1 TB)
Resize-Partition -DriveLetter C -Size 1073741824000
```

> If even PowerShell fails due to unmovable files at the end of the partition,
> boot a GParted live USB and resize from there — GParted ignores Windows
> file placement restrictions.

### 1.3 Re-enable pagefile (optional)

After shrinking, re-enable the pagefile in Virtual Memory settings if you want
one. With 64 GB RAM it's not essential.

---

## Part 2 — Create NixOS partitions (from the NixOS live installer)

Boot the NixOS minimal ISO. Open a root shell.

### 2.1 Identify the disk

```bash
lsblk -f
# Look for your 4 TB NVMe, typically /dev/nvme0n1
# Confirm the existing Windows partitions are p1–p3
DISK=/dev/nvme0n1
```

### 2.2 Create the two new partitions

Use `gdisk` (GPT-aware):

```bash
gdisk $DISK
```

Inside gdisk:

```
# Create NixOS EFI partition (512 MB)
Command: n
Partition number: 4
First sector: (press Enter for default — first free sector after Windows)
Last sector: +512M
Hex code: EF00   ← EFI System Partition type

# Create NixOS LUKS partition (remaining ~3 TB)
Command: n
Partition number: 5
First sector: (press Enter for default)
Last sector: (press Enter — use all remaining space)
Hex code: 8309   ← Linux LUKS type

# Write and exit
Command: w
```

Verify:

```bash
lsblk $DISK
# p4 should be 512M, p5 should be ~3T
```

### 2.3 Format the EFI partition

```bash
mkfs.fat -F32 -n NIXOS-EFI ${DISK}p4
```

---

## Part 3 — Set up LUKS2 encryption

```bash
# Format the LUKS container (you will be prompted to set a passphrase)
cryptsetup luksFormat \
  --type luks2 \
  --cipher aes-xts-plain64 \
  --key-size 512 \
  --hash sha512 \
  --iter-time 3000 \
  ${DISK}p5

# Open the LUKS container — maps it to /dev/mapper/cryptroot
cryptsetup luksOpen ${DISK}p5 cryptroot
```

> `--iter-time 3000` means 3 seconds of PBKDF work per unlock attempt.
> Increase to 5000 for stronger brute-force resistance (at the cost of ~2s
> extra at every boot).

---

## Part 4 — Create BTRFS and subvolumes

```bash
# Format BTRFS on the unlocked LUKS device
mkfs.btrfs -L nixos /dev/mapper/cryptroot

# Mount the top-level BTRFS volume (subvol ID 5)
mount /dev/mapper/cryptroot /mnt

# Create all subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@swap
btrfs subvolume create /mnt/@/.snapshots      # needs the @ subvol first
btrfs subvolume create /mnt/@home/.snapshots  # needs @home first

# Unmount the top-level volume
umount /mnt
```

---

## Part 5 — Mount everything for installation

```bash
BTRFS_OPTS="noatime,nodiratime,compress-force=zstd:1,space_cache=v2,discard=async"

mount -o subvol=@,$BTRFS_OPTS     /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,nix,var,swap,.snapshots,boot}
mkdir -p /mnt/home/.snapshots

mount -o subvol=@home,$BTRFS_OPTS  /dev/mapper/cryptroot /mnt/home
mount -o subvol=@nix,$BTRFS_OPTS   /dev/mapper/cryptroot /mnt/nix
mount -o subvol=@var,$BTRFS_OPTS   /dev/mapper/cryptroot /mnt/var
mount -o subvol=@swap,$BTRFS_OPTS  /dev/mapper/cryptroot /mnt/swap
mount -o subvol=@/.snapshots,$BTRFS_OPTS     /dev/mapper/cryptroot /mnt/.snapshots
mount -o subvol=@home/.snapshots,$BTRFS_OPTS /dev/mapper/cryptroot /mnt/home/.snapshots

# Mount NixOS EFI partition
mount ${DISK}p4 /mnt/boot
```

---

## Part 6 — Get UUIDs and update the config

```bash
# Get the LUKS partition UUID (the raw partition, not the mapper device)
lsblk -f ${DISK}p5
# Look for the UUID on the line with TYPE=crypto_LUKS

# Get the EFI partition UUID
lsblk -f ${DISK}p4
# Look for the UUID on the line with FSTYPE=vfat
```

Now update the two placeholder values in the repo:

**`nixos-configurations/homelab/hardware-configuration.nix`**:
```
REPLACE-WITH-LUKS-UUID  →  <UUID of nvme0n1p5>
REPLACE-WITH-EFI-UUID   →  <UUID of nvme0n1p4>
```

Also add your SSH public key in **`nixos-configurations/homelab/default.nix`**:
```nix
users.users.${username}.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... vino@bandit"
];
```

Commit and push the updated config before running nixos-install.

---

## Part 7 — Install NixOS

```bash
# Clone (or copy) the config repo onto the installer
nix-shell -p git
git clone https://github.com/6FaNcY9/nixos-config /mnt/etc/nixos-config
cd /mnt/etc/nixos-config

# Switch to your branch if needed
git checkout claude/review-homelab-setup-uvmjF

# Run the installer
nixos-install --flake .#homelab --root /mnt

# Set the root password when prompted (or leave blank if SSH key is your only access method)
```

---

## Part 8 — First boot checklist

- [ ] Machine boots and GRUB shows both NixOS and Windows entries
- [ ] LUKS passphrase prompt appears before NixOS boots
- [ ] SSH login works from bandit: `ssh vino@homelab` (or use Tailscale IP)
- [ ] Enable secrets (see commented steps in `default.nix` `features.security.secrets`)
- [ ] Re-enable pagefile in Windows if needed (boot into Windows to verify it still works)

---

## Troubleshooting

**Windows won't shrink past a certain point**
Unmovable system files (MFT zone, VSS, pagefile) block the shrink. Boot GParted
live USB and resize the NTFS partition from there — it will move files first.

**GRUB does not show Windows**
`useOSProber = true` is set but os-prober needs to run at build time. After the
first boot run `sudo nixos-rebuild switch` once to let os-prober scan and add
the Windows entry to grub.cfg.

**LUKS unlock fails at boot**
Confirm `REPLACE-WITH-LUKS-UUID` was replaced with the UUID of the raw
partition (`/dev/nvme0n1p5`), not the UUID of the BTRFS filesystem inside it.
`cryptsetup luksDump /dev/nvme0n1p5` shows the LUKS header with the correct UUID.

**`nixos-install` fails with "path does not exist"**
Make sure all subvolumes are mounted under `/mnt` before running the installer.
Run `findmnt --target /mnt` to verify.
