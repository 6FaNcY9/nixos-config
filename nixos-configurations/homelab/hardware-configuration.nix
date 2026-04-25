# Hardware configuration for host: homelab
#
# STUB — replace before first boot.
#
# On the target machine, run:
#   nixos-generate-config --show-hardware-config
# and replace this file with the output. Then update mainDisk UUID in default.nix.
#
# Expected storage layout (adjust to match actual partitioning):
#   - One 4TB NVMe: BTRFS with subvolumes @, @home, @nix, @var, @swap
#   - Separate EFI system partition for /boot
#   - Windows partition(s) on remaining space
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
  # PLACEHOLDER UUIDs — replace with actual values from lsblk -f
  # ---------------------------------------------------------------
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-BTRFS-UUID";
    fsType = "btrfs";
    options = [ "subvol=@" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-BTRFS-UUID";
    fsType = "btrfs";
    options = [ "subvol=@home" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-BTRFS-UUID";
    fsType = "btrfs";
    options = [ "subvol=@nix" ];
  };

  fileSystems."/var" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-BTRFS-UUID";
    fsType = "btrfs";
    options = [ "subvol=@var" ];
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-BTRFS-UUID";
    fsType = "btrfs";
    options = [ "subvol=@swap" ];
  };

  fileSystems."/.snapshots" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-BTRFS-UUID";
    fsType = "btrfs";
    options = [ "subvol=@/.snapshots" ];
  };

  fileSystems."/home/.snapshots" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-BTRFS-UUID";
    fsType = "btrfs";
    options = [ "subvol=@home/.snapshots" ];
  };

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
