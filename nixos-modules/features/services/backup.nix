# Feature: Restic Backup
# Provides: Automated encrypted backups with Restic
# Dependencies: features.security.secrets (for password file)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.services.backup;
in
{
  options.features.services.backup = {
    enable = lib.mkEnableOption "automated Restic backups";

    repositories = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
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
              default = [ "/home" ];
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
              default = [ "--read-data-subset=5%" ];
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
        }
      );
      default = { };
      description = "Backup repositories configuration";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User to run backups as (must have access to backup paths)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Dependency check: secrets recommended for password files
    warnings =
      lib.optionals (cfg.repositories == { }) [
        "features.services.backup.enable is true but no repositories are configured"
      ]
      ++ (lib.concatLists (
        lib.mapAttrsToList (
          name: repoCfg:
          lib.optional (repoCfg.initialize && repoCfg.passwordFile == null) ''
            Repository "${name}" has initialize=true but no passwordFile set
          ''
        ) cfg.repositories
      ))
      ++
        lib.optional (!(config.features.security.secrets.enable or false))
          "features.services.backup is enabled without features.security.secrets - password files should be managed via sops-nix";

    # Install Restic
    environment.systemPackages = [ pkgs.restic ];

    # Create backup services for each repository
    services.restic.backups = lib.mapAttrs (name: repoCfg: {
      inherit (repoCfg)
        repository
        passwordFile
        paths
        exclude
        pruneOpts
        timerConfig
        initialize
        environmentFile
        checkOpts
        ;
      inherit (cfg) user;

      # Backup script hooks
      backupPrepareCommand = ''
        echo "Starting backup: ${name}"
        echo "Repository: ${repoCfg.repository}"
        echo "Paths: ${lib.concatStringsSep ", " repoCfg.paths}"
      '';

      backupCleanupCommand = ''
        echo "Backup completed: ${name}"
        echo "Running prune to clean old backups..."
      '';

      # Additional restic options
      extraOptions = [
        "verbose=2" # Show more detailed progress (files being processed)
        "compression=auto"
      ];
    }) cfg.repositories;

    # Maintenance: Run repository checks weekly
    systemd.timers = lib.mapAttrs' (
      name: _:
      lib.nameValuePair "restic-check-${name}" {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
          RandomizedDelaySec = "2h";
        };
      }
    ) cfg.repositories;
  };
}
