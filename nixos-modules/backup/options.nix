# Module: backup/options.nix
# Purpose: Define backup configuration options
#
# Provides the backup.* option namespace with repository configuration
{lib, ...}: {
  options.backup = {
    enable = lib.mkEnableOption "automated backup service";

    repositories = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          repository = lib.mkOption {
            type = lib.types.str;
            description = "Restic repository path or URL";
            example = "/mnt/backup/restic/restic-repo";
          };

          passwordFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to file containing repository password";
            example = "/run/secrets/restic_password";
          };

          paths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["/home"];
            description = "Paths to back up";
          };

          exclude = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Patterns to exclude from backup";
          };

          timerConfig = lib.mkOption {
            type = lib.types.attrs;
            default = {
              OnCalendar = "00:03";
              RandomizedDelaySec = "1h";
              Persistent = true;
            };
            description = "Systemd timer configuration";
          };
        };
      });
      default = {};
      description = "Backup repositories configuration";
    };
  };
}
