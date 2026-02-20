# Feature: Swap Configuration
# Provides: Swap file or partition setup
# Dependencies: None
{
  lib,
  config,
  ...
}:
let
  cfg = config.features.storage.swap;
in
{
  options.features.storage.swap = {
    enable = lib.mkEnableOption "swap configuration";

    devices = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            device = lib.mkOption {
              type = lib.types.str;
              description = "Path to swap file or partition";
              example = "/swap/swapfile";
            };

            size = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "Size in MB (only for swap files, not partitions)";
            };

            priority = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "Swap priority (higher = preferred)";
            };
          };
        }
      );
      default = [ ];
      description = "Swap devices or files to configure";
      example = [
        { device = "/swap/swapfile"; }
        {
          device = "/dev/disk/by-label/swap";
          priority = 10;
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    swapDevices = map (
      swap:
      {
        inherit (swap) device;
      }
      // lib.optionalAttrs (swap.size != null) { inherit (swap) size; }
      // lib.optionalAttrs (swap.priority != null) { inherit (swap) priority; }
    ) cfg.devices;
  };
}
