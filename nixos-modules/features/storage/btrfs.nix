# Feature: BTRFS Maintenance
# Provides: BTRFS filesystem maintenance (fstrim, auto-scrub)
# Dependencies: BTRFS filesystems
{
  lib,
  config,
  ...
}:
let
  cfg = config.features.storage.btrfs;
in
{
  options.features.storage.btrfs = {
    enable = lib.mkEnableOption "BTRFS filesystem maintenance";

    fstrim = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable fstrim for SSD maintenance";
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "How often to run fstrim";
      };
    };

    autoScrub = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic BTRFS scrubbing";
      };

      fileSystems = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "BTRFS filesystems to scrub";
        example = [
          "/"
          "/home"
        ];
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "monthly";
        description = "How often to scrub BTRFS filesystems";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # SSD maintenance via fstrim
    services.fstrim = lib.mkIf cfg.fstrim.enable {
      enable = true;
      interval = cfg.fstrim.interval;
    };

    # BTRFS scrubbing for data integrity
    services.btrfs.autoScrub = lib.mkIf cfg.autoScrub.enable {
      enable = true;
      fileSystems = cfg.autoScrub.fileSystems;
      interval = cfg.autoScrub.interval;
    };

    # Warning if autoScrub enabled but no filesystems specified
    warnings = lib.optional (cfg.autoScrub.enable && cfg.autoScrub.fileSystems == [ ]) ''
      features.storage.btrfs.autoScrub is enabled but no filesystems specified.
      Set features.storage.btrfs.autoScrub.fileSystems to enable scrubbing.
    '';
  };
}
