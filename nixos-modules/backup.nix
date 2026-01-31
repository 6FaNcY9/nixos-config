# Automated backup configuration with Restic
# Provides encrypted, incremental backups to various backends
{
  lib,
  config,
  pkgs,
  ...
}: {
  options.backup = {
    enable = lib.mkEnableOption "automated backup with Restic";

    repositories = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          repository = lib.mkOption {
            type = lib.types.str;
            description = ''
              Repository URL (e.g., "s3:s3.amazonaws.com/bucket", "/mnt/backup", "sftp:user@host:/path")
            '';
          };

          passwordFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to file containing repository password";
          };

          paths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["/home"];
            description = "Paths to backup";
          };

          exclude = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              ".cache"
              "*.tmp"
              "*/node_modules"
              "*/.direnv"
              "*/target" # Rust build artifacts
              "*/dist" # JS build artifacts
              "*/build" # General build artifacts
            ];
            description = "Patterns to exclude from backup";
          };

          timerConfig = lib.mkOption {
            type = lib.types.attrs;
            default = {
              OnCalendar = "daily";
              Persistent = true;
              RandomizedDelaySec = "1h";
            };
            description = "Systemd timer configuration (when to run backups)";
          };

          pruneOpts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 6"
              "--keep-yearly 3"
            ];
            description = "Prune options for old backups";
          };

          checkOpts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["--read-data-subset=5%"];
            description = "Repository check options (verification)";
          };

          initialize = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Initialize repository on first run (WARNING: only enable for new repositories)";
          };

          environmentFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = ''
              Environment file for backend credentials (e.g., AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
              Example: /run/secrets/restic-env
            '';
          };
        };
      });
      default = {};
      description = "Backup repositories configuration";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User to run backups as (must have access to backup paths)";
    };
  };

  config = lib.mkIf config.backup.enable {
    # Install Restic
    environment.systemPackages = [pkgs.restic];

    # Create backup services for each repository
    services.restic.backups =
      lib.mapAttrs (name: cfg: {
        inherit (cfg) repository passwordFile paths exclude pruneOpts timerConfig initialize environmentFile;
        inherit (config.backup) user;

        # Backup script hooks
        backupPrepareCommand = ''
          # Safety check: Verify backup mount is actually mounted (not just a directory)
          BACKUP_DIR=$(dirname "${cfg.repository}")

          if ! mountpoint -q "$BACKUP_DIR"; then
            echo "ERROR: $BACKUP_DIR is not mounted"
            echo "Expected USB drive is not connected or not mounted"
            echo "Aborting backup to prevent writing to internal disk"
            exit 1
          fi

          # Extra safety: Verify it's not the root filesystem
          MOUNT_DEV=$(df "$BACKUP_DIR" | tail -1 | awk '{print $1}')
          if echo "$MOUNT_DEV" | grep -qE 'nvme|sda|vd'; then
            echo "ERROR: $BACKUP_DIR is on internal/system disk ($MOUNT_DEV)"
            echo "Expected external USB drive, aborting backup"
            exit 1
          fi

          echo "✓ Backup mount verified: $MOUNT_DEV mounted at $BACKUP_DIR"
          echo "Starting backup: ${name}"
          echo "Repository: ${cfg.repository}"
          echo "Paths: ${lib.concatStringsSep ", " cfg.paths}"
        '';

        backupCleanupCommand = ''
          echo "Backup completed: ${name}"
          echo "Running prune to clean old backups..."
        '';

        # Verify backups periodically (weekly)
        inherit (cfg) checkOpts;

        # Additional restic options
        extraOptions = [
          "verbose=2" # Show more detailed progress (files being processed)
          "compression=auto"
        ];
      })
      config.backup.repositories;

    # Maintenance: Run repository checks weekly
    systemd.timers = lib.mapAttrs' (name: _:
      lib.nameValuePair "restic-check-${name}" {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
          RandomizedDelaySec = "2h";
        };
      })
    config.backup.repositories;

    # Warnings for common issues
    warnings =
      lib.optionals (config.backup.repositories == {}) [
        "backup.enable is true but no repositories are configured"
      ]
      ++ (lib.concatLists (lib.mapAttrsToList (name: cfg:
        lib.optional (cfg.initialize && cfg.passwordFile == null) ''
          Repository "${name}" has initialize=true but no passwordFile set
        '')
      config.backup.repositories));
  };
}
