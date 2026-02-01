# Module: backup/power-check.nix
# Purpose: Battery-aware power management for backups
#
# Features:
#   - Only start backups on AC power or sufficient battery (>40%)
#   - Monitor battery during backup, stop if critical (<30%)
#   - Prevents battery drain during backup operations
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.backup;

  # Battery thresholds (Framework 13 AMD optimized)
  batteryThresholds = {
    minStart = 40; # Don't start backup if battery < 40%
    stopCritical = 30; # Stop backup if battery drops below 30%
  };

  # Power check script - runs before backup starts
  powerCheckScript = pkgs.writeShellScript "check-backup-power" ''
    set -euo pipefail

    # Get AC power status (1 = on AC, 0 = on battery)
    ac_online=$(cat /sys/class/power_supply/AC*/online 2>/dev/null || echo "0")

    # If on AC power, allow backup
    if [ "$ac_online" = "1" ]; then
      exit 0
    fi

    # On battery - check battery level
    battery_capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo "0")

    if [ "$battery_capacity" -lt ${toString batteryThresholds.minStart} ]; then
      echo "Battery level ($battery_capacity%) below minimum (${toString batteryThresholds.minStart}%). Skipping backup." >&2
      exit 1
    fi

    exit 0
  '';

  # Battery monitor script - runs during backup
  batteryMonitorScript = pkgs.writeShellScript "monitor-battery-during-backup" ''
    set -euo pipefail

    SERVICE_NAME="$1"

    while systemctl is-active "$SERVICE_NAME" >/dev/null 2>&1; do
      # Check if still on AC power
      ac_online=$(cat /sys/class/power_supply/AC*/online 2>/dev/null || echo "0")

      if [ "$ac_online" = "0" ]; then
        # On battery - check level
        battery_capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo "0")

        if [ "$battery_capacity" -lt ${toString batteryThresholds.stopCritical} ]; then
          echo "Battery level ($battery_capacity%) below stop threshold (${toString batteryThresholds.stopCritical}%). Stopping backup..." >&2
          systemctl stop "$SERVICE_NAME"
          exit 0
        fi
      fi

      sleep 30
    done
  '';
in {
  config = lib.mkIf cfg.enable {
    # Export scripts for use by other backup modules
    _module.args.backupPowerScripts = {
      inherit powerCheckScript batteryMonitorScript;
    };
  };
}
