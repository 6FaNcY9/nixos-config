{
  inputs,
  config,
  lib,
  ...
}:
let
  mainDisk = "/dev/disk/by-uuid/0629aaee-1698-49d1-b3e1-e7bb6b957cda";

  # Shared BTRFS mount options for SSD + battery optimization
  mkBtrfsOpts = subvol: [
    "subvol=${subvol}"
    "noatime"
    "nodiratime"
    "compress=zstd:3"
    "space_cache=v2"
    "discard=async"
  ];

in
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
  ];

  networking.hostName = "bandit";

  roles = {
    development = true; # Enable development tools (docker, direnv, build tools)
    desktop = true; # Enable
    laptop = true; # Enable laptop-specific behavior (bluetooth, power management)
  };

  # NEW: Feature modules
  features = {
    services = {
      tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };

      backup = {
        enable = false; # Currently disabled
        repositories.home = {
          repository = "/mnt/backup/restic";
          passwordFile = config.sops.secrets.restic_password.path;
          initialize = true;
          paths = [ "/home" ];
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

      # Monitoring (currently disabled for battery life)
      monitoring = {
        enable = false;
        grafana.enable = false;
        logging.enhancedJournal = true; # Keep enhanced logging (minimal overhead)
      };

      # Automated updates (timer disabled for battery life)
      auto-update = {
        enable = true; # Service available for manual triggering
        timer.enable = false; # Disabled for battery (2-4% per update, 10-15min CPU)
        timer.calendar = "monthly"; # When enabled, run monthly
      };

      # OpenSSH server (disabled on desktop/laptop)
      openssh.enable = false; # Enable on servers via roles.server

      # Trezor hardware wallet (enabled on desktop)
      trezord.enable = config.roles.desktop; # Hardware wallet support
    };

    desktop.i3-xfce = {
      enable = config.roles.desktop; # Enable when desktop role is active
      keyboardLayout = "at"; # Austrian keyboard
    };

    storage = {
      boot = {
        enable = true;
        bootloader = "grub";
        kernelPackage = "latest";
      };

      swap = {
        enable = true;
        devices = [ { device = "/swap/swapfile"; } ];
      };

      btrfs = {
        enable = true;
        fstrim.enable = true;
        autoScrub = {
          enable = true;
          fileSystems = [
            "/"
            "/home"
          ];
          interval = "monthly";
        };
      };

      snapper = {
        enable = true;
        enableTimeline = false; # Disabled for I/O reduction
        configs = {
          root = {
            subvolume = "/";
            numberLimit = "50";
          };
          home = {
            subvolume = "/home";
            numberLimit = "50";
          };
        };
      };
    };

    theme.stylix = {
      enable = true;
      targets.grub.enable = true;
      targets.lightdm.enable = true;
    };

    hardware.laptop = {
      enable = config.roles.laptop; # Enable when laptop role is active
      cpu.vendor = "amd";
      framework = {
        enable = true;
        model = "framework-13-amd";
      };
    };

    development.base = {
      enable = config.roles.development; # Enable when development role is active
      virtualization.docker.enable = false; # Disabled by default
      virtualization.podman.enable = false; # Disabled by default
    };

    security.secrets.enable = true;
  };

  desktop.variant = "i3-xfce";

  # Host-specific hibernate resume settings
  boot = {
    resumeDevice = mainDisk; # UUID-based resume device for hibernation
    kernelParams = [ "resume_offset=1959063" ]; # Calculated resume offset for swap partition (from `filefrag -v /swapfile`)
  };

  # Desktop Hardening - Enhanced security for desktop/laptop
  desktop.hardening.enable = true;

  # Filesystem optimizations (override hardware-configuration.nix)
  fileSystems = {
    "/mnt/backup" = {
      device = "/dev/disk/by-label/ResticBackup";
      fsType = "btrfs";
      options = [
        "nofail"
        "noatime"
        "compress=zstd"
      ];
    };

    "/" = {
      device = mainDisk;
      fsType = "btrfs";
      options = lib.mkForce (mkBtrfsOpts "@"); # Force options to override hardware-configuration.nix
    };
    "/home" = {
      device = mainDisk;
      fsType = "btrfs";
      options = lib.mkForce (mkBtrfsOpts "@home"); # Force options to override hardware-configuration.nix
    };
    "/nix" = {
      device = mainDisk;
      fsType = "btrfs";
      options = lib.mkForce (mkBtrfsOpts "@nix"); # Force options to override hardware-configuration.nix
    };
    "/var" = {
      device = mainDisk;
      fsType = "btrfs";
      options = lib.mkForce (mkBtrfsOpts "@var"); # Force options to override hardware-configuration.nix
    };
  };
}
