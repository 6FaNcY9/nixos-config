# Feature: Snapper Snapshots
# Provides: BTRFS snapshot management with snapper
# Dependencies: BTRFS filesystems
{
  lib,
  config,
  username,
  ...
}:
let
  cfg = config.features.storage.snapper;

  # Default snapper configuration template
  # Defines base snapshot retention policy and timeline settings that apply
  # to all configured subvolumes unless overridden in extraConfig.
  defaultSnapperConfig = {
    FSTYPE = "btrfs";
    TIMELINE_CLEANUP = true; # Automatically delete old snapshots based on timeline limits
    TIMELINE_LIMIT_HOURLY = "10"; # Keep last 10 hourly snapshots
    TIMELINE_LIMIT_DAILY = "7"; # Keep last 7 daily snapshots
    TIMELINE_LIMIT_WEEKLY = "0"; # No weekly snapshots (would use too much space)
    TIMELINE_LIMIT_MONTHLY = "0"; # No monthly snapshots
    TIMELINE_LIMIT_YEARLY = "0"; # No yearly snapshots
    NUMBER_CLEANUP = true; # Delete snapshots when total count exceeds limit
    ALLOW_USERS = [ username ]; # Users allowed to create/delete snapshots
  };
in
{
  options.features.storage.snapper = {
    enable = lib.mkEnableOption "snapper BTRFS snapshot management";

    enableTimeline = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable automatic timeline snapshots (hourly).
        Disabled by default to reduce I/O - manual snapshots and backups preferred.
      '';
    };

    configs = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            subvolume = lib.mkOption {
              type = lib.types.str;
              description = "BTRFS subvolume to snapshot";
              example = "/home";
            };

            numberLimit = lib.mkOption {
              type = lib.types.str;
              default = "50";
              description = "Maximum number of snapshots to keep";
            };

            timelineLimitHourly = lib.mkOption {
              type = lib.types.str;
              default = "10";
              description = "Number of hourly snapshots to keep";
            };

            timelineLimitDaily = lib.mkOption {
              type = lib.types.str;
              default = "7";
              description = "Number of daily snapshots to keep";
            };

            extraConfig = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Additional snapper configuration";
            };
          };
        }
      );
      default = { };
      description = "Snapper configurations for different subvolumes";
      example = {
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

  config = lib.mkIf cfg.enable {
    # Configure snapper for each specified subvolume
    services.snapper.configs = lib.mapAttrs (
      _name: snapCfg:
      defaultSnapperConfig
      // {
        SUBVOLUME = snapCfg.subvolume;
        NUMBER_LIMIT = snapCfg.numberLimit;
        TIMELINE_LIMIT_HOURLY = snapCfg.timelineLimitHourly;
        TIMELINE_LIMIT_DAILY = snapCfg.timelineLimitDaily;
      }
      // snapCfg.extraConfig
    ) cfg.configs;

    # Disable timeline timer if not explicitly enabled
    # This reduces I/O - manual snapshots and daily backups are preferred
    systemd.timers.snapper-timeline.enable = cfg.enableTimeline;

    # Warning if timeline disabled
    warnings = lib.optional (!cfg.enableTimeline) ''
      features.storage.snapper: Timeline snapshots disabled (reduces I/O).
      Snapshots can still be created manually with: snapper create --description "manual"
      To enable automatic hourly snapshots, set:
        features.storage.snapper.enableTimeline = true;
    '';
  };
}
