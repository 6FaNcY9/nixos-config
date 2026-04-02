# Device-specific configuration options
#
# Provides options for hardware-specific device names used by status
# bars, power management, and display configuration.
#
# Set these in host-specific configuration for accurate hardware detection.
{ lib, ... }:
{
  options.devices = {
    battery = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Battery device name for status widgets.";
    };

    backlight = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Backlight device name for status widgets.";
    };

    networkInterface = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Wireless interface name for status widgets (e.g., wlp1s0).";
    };

    lanInterface = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Wired ethernet interface name for status widgets (e.g., enp3s0). Leave empty if no ethernet port.";
    };
  };
}
