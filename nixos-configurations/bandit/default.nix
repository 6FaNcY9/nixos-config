{
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
  ];

  networking.hostName = "bandit";

  roles = {
    desktop = true;
    laptop = true;
  };

  desktop.variant = "i3-xfce";

  # Host-specific hibernate resume settings
  boot = {
    resumeDevice = "/dev/disk/by-uuid/0629aaee-1698-49d1-b3e1-e7bb6b957cda";
    kernelParams = ["resume_offset=1959063"];
  };

  # Desktop Hardening - Enhanced security for desktop/laptop
  desktop.hardening.enable = true;

  # System Monitoring - Prometheus, Grafana, and enhanced logging
  # DISABLED: Power-hungry on laptop (5-8% battery drain, 344MB RAM)
  # Re-enable when docked or debugging: monitoring.enable = true;
  # Access when enabled: Grafana at http://localhost:3000 (admin/admin)
  #                      Prometheus at http://localhost:9090
  monitoring = {
    enable = false; # ← DISABLED for battery life
    logging.enhancedJournal = true; # Keep enhanced logging (minimal overhead)
  };

  # Filesystem optimizations for battery life and performance
  # Override hardware-configuration.nix mount options
  fileSystems = {
    # Main filesystem optimizations
    # Use lib.mkForce to override hardware-configuration.nix settings
    # NOTE: BTRFS compression mount options are shared across ALL subvolumes
    # on the same filesystem. Using zstd:3 for better space savings.
    "/" = {
      device = "/dev/disk/by-uuid/0629aaee-1698-49d1-b3e1-e7bb6b957cda";
      fsType = "btrfs";
      options = lib.mkForce [
        "subvol=@"
        "noatime" # Don't update access times (reduces writes)
        "nodiratime" # Don't update directory access times
        "compress=zstd:3" # Good compression ratio with reasonable speed
        "space_cache=v2" # Better performance
        "discard=async" # SSD optimization
      ];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/0629aaee-1698-49d1-b3e1-e7bb6b957cda";
      fsType = "btrfs";
      options = lib.mkForce [
        "subvol=@home"
        "noatime"
        "nodiratime"
        "compress=zstd:3"
        "space_cache=v2"
        "discard=async"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/0629aaee-1698-49d1-b3e1-e7bb6b957cda";
      fsType = "btrfs";
      options = lib.mkForce [
        "subvol=@nix"
        "noatime"
        "compress=zstd:3" # Shared across all subvolumes (BTRFS limitation)
        "space_cache=v2"
        "discard=async"
      ];
    };

    "/var" = {
      device = "/dev/disk/by-uuid/0629aaee-1698-49d1-b3e1-e7bb6b957cda";
      fsType = "btrfs";
      options = lib.mkForce [
        "subvol=@var"
        "noatime"
        "nodiratime"
        "compress=zstd:3"
        "space_cache=v2"
        "discard=async"
      ];
    };
  };
}
