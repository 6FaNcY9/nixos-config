{
  inputs,
  config,
  lib,
  ...
}: let
  mainDisk = "/dev/disk/by-uuid/0629aaee-1698-49d1-b3e1-e7bb6b957cda";

  # Shared BTRFS mount options for SSD + battery optimization
  mkBtrfsOpts = subvol:
    lib.mkForce ([
        "subvol=${subvol}"
        "noatime"
        "nodiratime"
        "compress=zstd:3"
        "space_cache=v2"
        "discard=async"
      ]
      ++ lib.optionals (subvol == "@nix") []);
in {
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
    resumeDevice = mainDisk;
    kernelParams = ["resume_offset=1959063"];
  };

  # Desktop Hardening - Enhanced security for desktop/laptop
  desktop.hardening.enable = true;

  # System Monitoring - Prometheus, Grafana, and enhanced logging
  # DISABLED: Power-hungry on laptop (5-8% battery drain, 344MB RAM)
  monitoring = {
    enable = false;
    grafana.enable = false;
    logging.enhancedJournal = true; # Keep enhanced logging (minimal overhead)
  };

  # Automated Backups - Encrypted incremental backups with Restic
  # External 128GB USB drive (BTRFS), labeled "ResticBackup"
  backup = {
    enable = false;
    repositories.home = {
      repository = "/mnt/backup/restic";
      passwordFile = config.sops.secrets.restic_password.path;
      initialize = true;
      paths = ["/home"];
      exclude = [
        ".cache"
        "*.tmp"
        "*/node_modules"
        "*/.direnv"
        "*/target"
        "*/dist"
        "*/build"
        "*/.local/share/Trash"
        "*/.snapshots"
      ];
    };
  };

  # Filesystem optimizations (override hardware-configuration.nix)
  fileSystems = {
    "/mnt/backup" = {
      device = "/dev/disk/by-label/ResticBackup";
      fsType = "btrfs";
      options = ["nofail" "noatime" "compress=zstd"];
    };

    "/" = {
      device = mainDisk;
      fsType = "btrfs";
      options = mkBtrfsOpts "@";
    };
    "/home" = {
      device = mainDisk;
      fsType = "btrfs";
      options = mkBtrfsOpts "@home";
    };
    "/nix" = {
      device = mainDisk;
      fsType = "btrfs";
      options = mkBtrfsOpts "@nix";
    };
    "/var" = {
      device = mainDisk;
      fsType = "btrfs";
      options = mkBtrfsOpts "@var";
    };
  };
}
