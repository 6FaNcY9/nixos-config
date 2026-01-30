# User systemd services and timers
# Provides example user-level automation services
{
  lib,
  config,
  pkgs,
  ...
}: {
  options.userServices = {
    homeBackup = {
      enable = lib.mkEnableOption "daily backup of important home directory files";

      backupPath = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.local/share/backups";
        description = "Where to store backups";
      };

      paths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "${config.home.homeDirectory}/Documents"
          "${config.home.homeDirectory}/.config"
        ];
        description = "Paths to backup";
      };
    };

    gitSync = {
      enable = lib.mkEnableOption "automatic git repository sync for dotfiles";

      repoPath = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.dotfiles";
        description = "Path to git repository to sync";
      };

      commitMessage = lib.mkOption {
        type = lib.types.str;
        default = "auto: sync dotfiles [$(date +'%Y-%m-%d %H:%M')]";
        description = "Commit message template";
      };
    };
  };

  config = lib.mkMerge [
    # Home backup service
    (lib.mkIf config.userServices.homeBackup.enable {
      systemd.user.services.home-backup = {
        Unit = {
          Description = "Backup important home directory files";
          After = ["network.target"];
        };

        Service = {
          Type = "oneshot";
          ExecStart = let
            backupScript = pkgs.writeShellScript "home-backup" ''
              set -euo pipefail

              BACKUP_DIR="${config.userServices.homeBackup.backupPath}"
              TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
              BACKUP_NAME="home_backup_$TIMESTAMP.tar.gz"

              mkdir -p "$BACKUP_DIR"

              echo "Creating backup: $BACKUP_NAME"
              tar czf "$BACKUP_DIR/$BACKUP_NAME" \
                ${lib.concatStringsSep " " (map (p: ''"${p}"'') config.userServices.homeBackup.paths)} \
                2>/dev/null || true

              echo "Backup created: $BACKUP_DIR/$BACKUP_NAME"

              # Keep only last 7 backups
              cd "$BACKUP_DIR"
              ls -t home_backup_*.tar.gz | tail -n +8 | xargs -r rm

              echo "Cleanup complete. Current backups:"
              ls -lh home_backup_*.tar.gz
            '';
          in "${backupScript}";
        };
      };

      systemd.user.timers.home-backup = {
        Unit = {
          Description = "Daily home directory backup";
        };

        Timer = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };

        Install = {
          WantedBy = ["timers.target"];
        };
      };
    })

    # Git sync service
    (lib.mkIf config.userServices.gitSync.enable {
      systemd.user.services.git-sync = {
        Unit = {
          Description = "Sync git repository (dotfiles)";
          After = ["network-online.target"];
          Wants = ["network-online.target"];
        };

        Service = {
          Type = "oneshot";
          ExecStart = let
            syncScript = pkgs.writeShellScript "git-sync" ''
              set -euo pipefail

              REPO="${config.userServices.gitSync.repoPath}"

              if [ ! -d "$REPO/.git" ]; then
                echo "Not a git repository: $REPO"
                exit 0
              fi

              cd "$REPO"

              # Check if there are changes
              if ! git diff --quiet || ! git diff --cached --quiet; then
                echo "Changes detected, committing..."
                git add -A
                git commit -m "${config.userServices.gitSync.commitMessage}" || true
              fi

              # Pull latest changes (rebase to avoid merge commits)
              echo "Pulling latest changes..."
              git pull --rebase || true

              # Push changes
              echo "Pushing changes..."
              git push || true

              echo "Sync complete"
            '';
          in "${syncScript}";
        };
      };

      systemd.user.timers.git-sync = {
        Unit = {
          Description = "Periodic git repository sync";
        };

        Timer = {
          OnCalendar = "hourly";
          Persistent = true;
          RandomizedDelaySec = "10m";
        };

        Install = {
          WantedBy = ["timers.target"];
        };
      };
    })
  ];
}
