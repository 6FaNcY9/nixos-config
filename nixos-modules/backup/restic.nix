# Module: backup/restic.nix
# Purpose: Restic backup service configuration
#
# Features:
#   - Automated daily backups via systemd timer
#   - USB auto-mount support (ResticBackup label)
#   - Retention policy: 7 daily, 4 weekly, 6 monthly, 3 yearly
#   - Monthly prune operations
{
  lib,
  pkgs,
  config,
  username ? "vino",
  backupPowerScripts ? null,
  ...
}: let
  cfg = config.backup;

  # Backup configuration constants
  backupUser = username;
  backupDriveLabel = "ResticBackup";
  backupMountPoint = "/mnt/backup/restic";
  
  # Default exclude patterns (optimized for development workstation)
  defaultExcludePatterns = [
    "/home/.snapshots" # BTRFS snapshots (redundant)
    "/home/*/.cache"
    "/home/*/.local/share/Trash"
    "/home/*/Downloads" # Large files, not critical
    "/home/*/.thumbnails"
    "/home/*/.npm"
    "/home/*/.cargo/registry" # Can be rebuilt
    "/home/*/.rustup" # Can be reinstalled
    "/home/*/node_modules" # Can be rebuilt
    "/home/*/.vscode" # Extensions can be reinstalled
    "/home/*/.gradle"
    "*.tmp"
    "*.temp"
  ];

  # Backup script for each repository
  mkBackupScript = name: repo: let
    powerCheck = backupPowerScripts.powerCheckScript or (pkgs.writeShellScript "noop-power-check" "exit 0");
    batteryMonitor = backupPowerScripts.batteryMonitorScript or (pkgs.writeShellScript "noop-battery-monitor" ":");
  in
    pkgs.writeShellScript "restic-backup-${name}" ''
      set -euo pipefail

      # Check power before starting
      if ! ${powerCheck}; then
        echo "Power check failed. Backup aborted." >&2
        exit 1
      fi

      # Check if drive is mounted (for local repositories)
      if [[ "${repo.repository}" == /mnt/* ]]; then
        if ! ${pkgs.util-linux}/bin/mountpoint -q ${backupMountPoint}; then
          echo "Backup drive not mounted at ${backupMountPoint}. Aborting." >&2
          exit 1
        fi
      fi

      # Check if repository exists
      if ! ${pkgs.restic}/bin/restic -r ${repo.repository} --password-file=${repo.passwordFile} snapshots >/dev/null 2>&1; then
        echo "Restic repository not initialized. Please run restic init first." >&2
        exit 1
      fi

      # Start battery monitor in background
      ${batteryMonitor} restic-backup-${name}.service &
      MONITOR_PID=$!

      # Cleanup function
      cleanup() {
        kill $MONITOR_PID 2>/dev/null || true
      }
      trap cleanup EXIT

      echo "Starting backup of ${lib.concatStringsSep ", " repo.paths}..."

      # Run backup
      ${pkgs.restic}/bin/restic -r ${repo.repository} \
        --password-file=${repo.passwordFile} \
        backup ${lib.concatStringsSep " " repo.paths} \
        ${lib.concatMapStringsSep " " (p: "--exclude '${p}'") (repo.exclude ++ defaultExcludePatterns)} \
        --one-file-system \
        --tag automated \
        --tag daily

      echo "Backup completed successfully."
    '';

  # Initialization script for first-time setup
  mkInitScript = name: repo:
    pkgs.writeShellScript "restic-init-${name}" ''
      set -euo pipefail

      echo "Initializing Restic repository at ${repo.repository}..."

      # Check if drive is mounted (for local repositories)
      if [[ "${repo.repository}" == /mnt/* ]]; then
        if ! ${pkgs.util-linux}/bin/mountpoint -q ${backupMountPoint}; then
          echo "Backup drive not mounted. Mounting..." >&2
          mkdir -p ${backupMountPoint}
          mount -L ${backupDriveLabel} ${backupMountPoint} || {
            echo "Failed to mount backup drive. Please check if drive with label '${backupDriveLabel}' is connected." >&2
            exit 1
          }
        fi
      fi

      # Create repository directory
      mkdir -p ${repo.repository}

      # Initialize repository
      ${pkgs.restic}/bin/restic -r ${repo.repository} --password-file=${repo.passwordFile} init || {
        if ${pkgs.restic}/bin/restic -r ${repo.repository} --password-file=${repo.passwordFile} snapshots >/dev/null 2>&1; then
          echo "Repository already initialized."
        else
          echo "Failed to initialize repository." >&2
          exit 1
        fi
      }

      echo "Repository initialized successfully."
    '';
in {
  config = lib.mkIf cfg.enable {
    # Systemd services for each repository
    systemd.services = lib.mapAttrs' (name: repo:
      lib.nameValuePair "restic-backup-${name}" {
        description = "Restic backup to ${name}";
        after = ["network.target"];
        
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          ExecStart = "${mkBackupScript name repo}";
          
          # Security hardening
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          ReadWritePaths = [repo.repository];
        };
      }
    ) cfg.repositories;

    # Systemd timers for automated backups
    systemd.timers = lib.mapAttrs' (name: repo:
      lib.nameValuePair "restic-backup-${name}" {
        description = "Timer for restic backup to ${name}";
        wantedBy = ["timers.target"];
        
        timerConfig = repo.timerConfig // {
          Unit = "restic-backup-${name}.service";
        };
      }
    ) cfg.repositories;

    # Helper scripts for manual operations
    environment.systemPackages =
      lib.flatten (lib.mapAttrsToList (name: repo: [
        (pkgs.writeShellScriptBin "restic-init-${name}" ''
          exec ${mkInitScript name repo} "$@"
        '')
        
        (pkgs.writeShellScriptBin "restic-backup-${name}-now" ''
          echo "Running immediate backup to ${name}..."
          systemctl start restic-backup-${name}.service
        '')
        
        (pkgs.writeShellScriptBin "restic-prune-${name}" ''
          echo "Pruning old snapshots from ${name}..."
          ${pkgs.restic}/bin/restic -r ${repo.repository} \
            --password-file=${repo.passwordFile} \
            forget \
            --keep-daily 7 \
            --keep-weekly 4 \
            --keep-monthly 6 \
            --keep-yearly 3 \
            --prune
        '')
      ]) cfg.repositories);

    # USB auto-mount for backup drive
    services.udev.extraRules = ''
      # Auto-mount ResticBackup USB drive
      SUBSYSTEM=="block", ENV{ID_FS_LABEL}=="${backupDriveLabel}", ENV{ID_FS_TYPE}=="btrfs", ACTION=="add", RUN+="${pkgs.util-linux}/bin/mount -L ${backupDriveLabel} ${backupMountPoint}"
    '';

    # Create mount point
    systemd.tmpfiles.rules = [
      "d ${backupMountPoint} 0755 root root -"
    ];
  };
}
