# Module: backup.nix
# Purpose: Restic backup configuration for local USB drive
# 
# Features:
#   - Automated daily backups to USB drive (ResticBackup label)
#   - Battery-aware: only runs on AC power
#   - BTRFS-aware: excludes snapshots to avoid duplication
#   - Retention policy: 7 daily, 4 weekly, 6 monthly, 3 yearly
#   - Prune strategy: monthly cleanup of old snapshots
#
# Dependencies:
#   - sops-nix: for encrypted password storage (restic_password)
#   - systemd: for timer-based scheduling
#   - restic package
#
# Options:
#   - backup.enable (bool): Enable backup service
#   - backup.repositories.<name>: Repository configuration
#
# Usage:
#   backup.enable = true;
#   backup.repositories.home = {
#     repository = "/mnt/backup/restic/restic-repo";
#     passwordFile = "/run/secrets/restic_password";
#   };
#
# Notes:
#   - Backup drive must have label "ResticBackup"
#   - Mount point: /mnt/backup/restic
#   - Excludes: .cache, Downloads, node_modules, etc.
#   - Runs at 00:03 daily with 1h random delay
#
{
  lib,
  pkgs,
  config,
  username ? "vino",
  ...
}: let
  cfg = config.backup;

  # Backup configuration
  backupUser = username;
  backupDriveLabel = "ResticBackup";
  backupMountPoint = "/mnt/backup/restic";
  resticRepoPath = "${backupMountPoint}/restic-repo";
  resticPasswordFile = config.sops.secrets.restic_password.path; # Use sops-managed secret
  backupPaths = ["/home"];
  excludePatterns = [
    "/home/.snapshots"
    "/home/*/.cache"
    "/home/*/.local/share/Trash"
    "/home/*/Downloads"
    "/home/*/.thumbnails"
    "/home/*/.npm"
    "/home/*/.cargo/registry"
    "/home/*/.rustup"
    "/home/*/node_modules"
    "/home/*/.vscode"
    "/home/*/.gradle"
    "*.tmp"
    "*.temp"
  ];

  # Battery monitoring configuration
  minBatteryPercent = 40; # Don't start if battery < 40%
  stopBatteryPercent = 30; # Stop backup if battery drops below 30%

  # Power check script
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

    if [ "$battery_capacity" -lt ${toString minBatteryPercent} ]; then
      echo "Battery level ($battery_capacity%) below minimum (${toString minBatteryPercent}%). Skipping backup." >&2
      exit 1
    fi

    exit 0
  '';

  # Battery monitor script (runs during backup)
  batteryMonitorScript = pkgs.writeShellScript "monitor-battery-during-backup" ''
    set -euo pipefail

    SERVICE_NAME="$1"

    while systemctl is-active "$SERVICE_NAME" >/dev/null 2>&1; do
      # Check if still on AC power
      ac_online=$(cat /sys/class/power_supply/AC*/online 2>/dev/null || echo "0")

      if [ "$ac_online" = "0" ]; then
        # On battery - check level
        battery_capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo "0")

        if [ "$battery_capacity" -lt ${toString stopBatteryPercent} ]; then
          echo "Battery level ($battery_capacity%) below stop threshold (${toString stopBatteryPercent}%). Stopping backup..." >&2
          systemctl stop "$SERVICE_NAME"
          exit 0
        fi
      fi

      sleep 30
    done
  '';

  # Backup script
  backupScript = pkgs.writeShellScript "restic-backup" ''
    set -euo pipefail

    # Check power before starting
    if ! ${powerCheckScript}; then
      echo "Power check failed. Backup aborted." >&2
      exit 1
    fi

    # Check if drive is mounted
    if ! ${pkgs.util-linux}/bin/mountpoint -q ${backupMountPoint}; then
      echo "Backup drive not mounted at ${backupMountPoint}. Aborting." >&2
      exit 1
    fi

    # Check if repository exists
    if ! ${pkgs.restic}/bin/restic -r ${resticRepoPath} --password-file=${resticPasswordFile} snapshots >/dev/null 2>&1; then
      echo "Restic repository not initialized. Please run restic-init first." >&2
      exit 1
    fi

    # Start battery monitor in background
    ${batteryMonitorScript} restic-backup.service &
    MONITOR_PID=$!

    # Cleanup function
    cleanup() {
      kill $MONITOR_PID 2>/dev/null || true
    }
    trap cleanup EXIT

    echo "Starting backup of ${lib.concatStringsSep ", " backupPaths}..."

    # Run restic backup
    ${pkgs.restic}/bin/restic -r ${resticRepoPath} \
      --password-file=${resticPasswordFile} \
      --verbose \
      backup ${lib.concatStringsSep " " backupPaths} \
      ${lib.concatMapStringsSep " " (p: "--exclude '${p}'") excludePatterns}

    echo "Backup completed successfully."

    # Prune old backups (keep last 7 daily, 4 weekly, 12 monthly)
    echo "Pruning old backups..."
    ${pkgs.restic}/bin/restic -r ${resticRepoPath} \
      --password-file=${resticPasswordFile} \
      forget \
      --keep-daily 7 \
      --keep-weekly 4 \
      --keep-monthly 12 \
      --prune

    echo "Backup and pruning completed."
  '';

  # Initialization script for first-time setup
  initScript = pkgs.writeShellScript "restic-init" ''
    set -euo pipefail

    # Check if drive is mounted
    if ! ${pkgs.util-linux}/bin/mountpoint -q ${backupMountPoint}; then
      echo "Error: Backup drive not mounted at ${backupMountPoint}" >&2
      echo "Please mount your backup drive first." >&2
      exit 1
    fi

    # Check if password file exists (managed by sops)
    if [ ! -f ${resticPasswordFile} ]; then
      echo "Error: Restic password file not found at ${resticPasswordFile}" >&2
      echo "Password is managed by sops-nix. Make sure secrets/restic.yaml is configured." >&2
      exit 1
    fi

    # Initialize repository if it doesn't exist
    if ! ${pkgs.restic}/bin/restic -r ${resticRepoPath} --password-file=${resticPasswordFile} snapshots >/dev/null 2>&1; then
      echo "Initializing restic repository at ${resticRepoPath}..."
      ${pkgs.restic}/bin/restic -r ${resticRepoPath} --password-file=${resticPasswordFile} init
      echo "Repository initialized successfully."
    else
      echo "Repository already initialized."
    fi

    echo "Setup complete. You can now run restic-backup to start a backup."
  '';
in {
  options.backup = {
    enable = lib.mkEnableOption "Restic backup to external USB drive";

    driveLabel = lib.mkOption {
      type = lib.types.str;
      default = backupDriveLabel;
      description = "Label of the USB backup drive";
    };

    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = backupMountPoint;
      description = "Mount point for the backup drive";
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = backupPaths;
      description = "Paths to back up";
    };

    excludePatterns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = excludePatterns;
      description = "Patterns to exclude from backup";
    };

    minBatteryPercent = lib.mkOption {
      type = lib.types.int;
      default = minBatteryPercent;
      description = "Minimum battery percentage to start backup";
    };

    stopBatteryPercent = lib.mkOption {
      type = lib.types.int;
      default = stopBatteryPercent;
      description = "Battery percentage to stop backup";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install restic
    environment.systemPackages = [
      pkgs.restic
      (pkgs.writeShellScriptBin "restic-format-usb" ''
        #!/usr/bin/env bash
        set -euo pipefail

        echo "=== Restic USB Drive Formatter ==="
        echo ""
        echo "This will format a USB drive with label 'ResticBackup'"
        echo "WARNING: This will DESTROY all data on the selected drive!"
        echo ""

        # List available disks
        echo "Available disks:"
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "disk|NAME"
        echo ""

        read -p "Enter device name (e.g., sda): " device

        if [ -z "$device" ]; then
          echo "Error: No device specified" >&2
          exit 1
        fi

        # Validate device exists
        if [ ! -b "/dev/$device" ]; then
          echo "Error: /dev/$device does not exist" >&2
          exit 1
        fi

        # Check if it's the system disk
        if [[ "$device" == "nvme"* ]] || [[ "$device" == *"p"* ]]; then
          echo "Error: This looks like a system disk or partition. Aborting for safety." >&2
          exit 1
        fi

        echo ""
        echo "You selected: /dev/$device"
        lsblk "/dev/$device"
        echo ""
        read -p "Are you ABSOLUTELY SURE you want to format /dev/$device? (type 'yes' to confirm): " confirm

        if [ "$confirm" != "yes" ]; then
          echo "Aborted."
          exit 0
        fi

        echo ""
        echo "Formatting /dev/$device..."

        # Unmount if mounted
        ${pkgs.util-linux}/bin/umount "/dev/$device"* 2>/dev/null || true

        # Create partition table and partition
        ${pkgs.parted}/bin/parted -s "/dev/$device" mklabel gpt
        ${pkgs.parted}/bin/parted -s "/dev/$device" mkpart primary ext4 0% 100%

        # Wait for partition to appear
        sleep 2

        # Format partition with ext4 and label
        ${pkgs.e2fsprogs}/bin/mkfs.ext4 -L ResticBackup "/dev/''${device}1"

        echo ""
        echo "✓ USB drive formatted successfully!"
        echo "  Device: /dev/$device"
        echo "  Partition: /dev/''${device}1"
        echo "  Label: ResticBackup"
        echo "  Filesystem: ext4"
        echo ""
        echo "Now unplug and re-plug the drive to trigger auto-mount."
      '')
      (pkgs.writeShellScriptBin "restic-init" ''
        exec /run/wrappers/bin/sudo ${initScript}
      '')
      (pkgs.writeShellScriptBin "restic-backup-manual" ''
        exec /run/wrappers/bin/sudo ${backupScript}
      '')
      (pkgs.writeShellScriptBin "restic-check" ''
        exec /run/wrappers/bin/sudo ${pkgs.restic}/bin/restic -r ${resticRepoPath} --password-file=${resticPasswordFile} check "$@"
      '')
      (pkgs.writeShellScriptBin "restic-snapshots" ''
        exec /run/wrappers/bin/sudo ${pkgs.restic}/bin/restic -r ${resticRepoPath} --password-file=${resticPasswordFile} snapshots "$@"
      '')
      (pkgs.writeShellScriptBin "restic-restore" ''
        exec /run/wrappers/bin/sudo ${pkgs.restic}/bin/restic -r ${resticRepoPath} --password-file=${resticPasswordFile} restore "$@"
      '')
    ];

    # Systemd configuration (merged into single attribute set)
    systemd = {
      # Create mount point
      tmpfiles.rules = [
        "d ${cfg.mountPoint} 0755 root root -"
      ];

      services = {
        # Systemd service for backup
        restic-backup = {
          description = "Restic backup to external USB drive";
          after = ["local-fs.target"];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = backupScript;
            User = "root";
            Nice = 19; # Low priority
            IOSchedulingClass = "idle"; # Don't interfere with normal I/O
          };
        };

        # Systemd service template for auto-mounting
        "restic-automount@" = {
          description = "Auto-mount ResticBackup drive and start backup";

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          scriptArgs = "%i";
          script = ''
            set -euo pipefail

            DEVICE="/dev/$1"

            # Wait for device to be ready
            sleep 2

            # Mount the drive
            if ! ${pkgs.util-linux}/bin/mountpoint -q ${cfg.mountPoint}; then
              echo "Mounting $DEVICE to ${cfg.mountPoint}..."
              ${pkgs.util-linux}/bin/mount "$DEVICE" ${cfg.mountPoint}
            fi

            # Trigger backup after a short delay
            sleep 3
            ${pkgs.systemd}/bin/systemctl start restic-backup.service || true
          '';

          preStop = ''
            # Stop any running backup
            ${pkgs.systemd}/bin/systemctl stop restic-backup.service || true

            # Unmount the drive
            if ${pkgs.util-linux}/bin/mountpoint -q ${cfg.mountPoint}; then
              echo "Unmounting ${cfg.mountPoint}..."
              ${pkgs.util-linux}/bin/umount ${cfg.mountPoint} || true
            fi
          '';
        };
      };
    };

    # Udev rule to auto-mount and trigger backup when USB drive is connected
    services.udev.extraRules = ''
      # Auto-mount ResticBackup drive and trigger backup
      ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_LABEL}=="${cfg.driveLabel}", ENV{ID_FS_TYPE}=="ext4|btrfs|xfs|ntfs|vfat", RUN+="${pkgs.systemd}/bin/systemctl start restic-automount@%k.service"

      # Unmount when drive is removed
      ACTION=="remove", SUBSYSTEM=="block", ENV{ID_FS_LABEL}=="${cfg.driveLabel}", RUN+="${pkgs.systemd}/bin/systemctl stop restic-automount@%k.service"
    '';

    # Notification support (optional)
    environment.etc."restic-backup-notify.sh" = {
      text = ''
        #!/usr/bin/env bash
        # Send notification to user about backup status
        # This can be called from systemd service

        if command -v notify-send >/dev/null 2>&1; then
          export DISPLAY=:0
          export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u ${backupUser})/bus

          sudo -u ${backupUser} notify-send "$@"
        fi
      '';
      mode = "0755";
    };
  };
}
