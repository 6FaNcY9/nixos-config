# Hardware configuration for host: homelab
#
# STUB — replace kernel modules and UUIDs before first boot.
#
# After partitioning (see docs/homelab-partition-guide.md):
#   1. Boot the NixOS installer
#   2. Open the LUKS container:  cryptsetup luksOpen /dev/nvme0n1pX cryptroot
#   3. Get the LUKS partition UUID: lsblk -f /dev/nvme0n1pX   (TYPE=crypto_LUKS)
#   4. Get the EFI partition UUID:  lsblk -f /dev/nvme0n1pY   (TYPE=vfat)
#   5. Replace REPLACE-WITH-LUKS-UUID and REPLACE-WITH-EFI-UUID below
#   6. Run nixos-generate-config --show-hardware-config and merge any extra kernel modules
#
# Partition layout expected (adjust device names to match your NVMe):
#   nvme0n1p1  Windows Recovery  (~600 MB)
#   nvme0n1p2  Windows EFI       (~100 MB, leave untouched)
#   nvme0n1p3  Windows C:        (~1 TB, shrunk from 4 TB)
#   nvme0n1p4  NixOS EFI         (512 MB, vfat)
#   nvme0n1p5  NixOS LUKS        (~3 TB, LUKS2 → /dev/mapper/cryptroot → BTRFS)
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "uas"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ]; # Intel i9
  boot.extraModulePackages = [ ];

  # ---------------------------------------------------------------
  # LUKS2 encrypted NixOS partition
  # Replace REPLACE-WITH-LUKS-UUID with the UUID of the raw LUKS partition
  # (not the BTRFS filesystem inside it).  Get it with: lsblk -f
  # ---------------------------------------------------------------
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-LUKS-UUID";
    allowDiscards = true; # Pass TRIM commands through LUKS to the NVMe
  };

  # ---------------------------------------------------------------
  # Filesystem stubs — optimized mount options are applied via
  # lib.mkForce in nixos-configurations/homelab/default.nix.
  # All BTRFS subvolumes live on /dev/mapper/cryptroot.
  # ---------------------------------------------------------------
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@" ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@home" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@nix" ];
  };

  fileSystems."/var" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@var" ];
  };

  fileSystems."/swap" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@swap" ];
  };

  fileSystems."/.snapshots" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@/.snapshots" ];
  };

  fileSystems."/home/.snapshots" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@home/.snapshots" ];
  };

  # ---------------------------------------------------------------
  # NixOS EFI partition (separate from the Windows EFI partition)
  # Replace REPLACE-WITH-EFI-UUID with the UUID of nvme0n1p4.
  # ---------------------------------------------------------------
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-EFI-UUID";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
