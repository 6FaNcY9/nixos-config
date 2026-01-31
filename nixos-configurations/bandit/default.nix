{
  inputs,
  config,
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
    grafana.enable = false;
    logging.enhancedJournal = true; # Keep enhanced logging (minimal overhead)
  };

  # Automated Backups - Encrypted incremental backups with Restic
  # CONFIGURATION: External 128GB USB drive formatted with BTRFS
  # CAPACITY: Current data ~2.6GB, drive can hold 15-20GB after 1 year with deduplication
  # LOCATION: /mnt/backup (auto-mount from USB drive labeled "ResticBackup")
  # RETENTION: 7 daily, 4 weekly, 6 monthly, 3 yearly snapshots
  # SCHEDULE: Daily at 00:03 with 1-hour random delay
  # NOTE: Plug in USB drive before backups run, or backup will fail gracefully (nofail option)
  backup = {
    enable = true;
    repositories.home = {
      repository = "/mnt/backup/restic"; # 128GB USB drive (BTRFS)
      passwordFile = config.sops.secrets.restic_password.path;
      initialize = true; # Auto-initialize repository on first run (using sops password)
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
        # Exclude snapper snapshots (302GB, already on internal drive)
        "*/.snapshots"
      ];
    };
  };

  # Filesystem optimizations for battery life and performance
  # Override hardware-configuration.nix mount options
  fileSystems = {
    # Auto-mount external backup USB drive
    # USB drive must be formatted as BTRFS and labeled "ResticBackup"
    # nofail = don't prevent boot if USB not connected
    "/mnt/backup" = {
      device = "/dev/disk/by-label/ResticBackup";
      fsType = "btrfs";
      options = [
        "nofail" # Don't fail boot if USB not plugged in
        "noatime" # Don't update access times (saves writes)
        "compress=zstd" # Enable compression (saves space)
      ];
    };

    # Main filesystem optimizations
    "/" = {
      options = [
        "subvol=@"
        "noatime" # Don't update access times (reduces writes)
        "nodiratime" # Don't update directory access times
        "compress=zstd:1" # Lighter compression for faster I/O
        "space_cache=v2" # Better performance
        "discard=async" # SSD optimization
      ];
    };

    "/home" = {
      options = [
        "subvol=@home"
        "noatime"
        "nodiratime"
        "compress=zstd:1"
        "space_cache=v2"
        "discard=async"
      ];
    };

    "/nix" = {
      options = [
        "subvol=@nix"
        "noatime"
        "compress=zstd:3" # Keep higher compression for /nix (store rarely accessed)
        "space_cache=v2"
        "discard=async"
      ];
    };

    "/var" = {
      options = [
        "subvol=@var"
        "noatime"
        "nodiratime"
        "compress=zstd:1"
        "space_cache=v2"
        "discard=async"
      ];
    };
  };
}
