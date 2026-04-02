# Security: ClamAV on-demand antivirus scanner
#
# Provides three scan commands via the `clamav-scan` wrapper script:
#   clamav-scan home    — scans $HOME
#   clamav-scan system  — scans /
#   clamav-scan <path>  — scans a specific path
#
# Virus definitions are updated once at boot via freshclam (no recurring timer).
# Infected files are moved to /var/lib/clamav-quarantine (never auto-deleted).
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.features.security.clamav;
  quarantine = "/var/lib/clamav-quarantine";
  systemExcludes = [
    "/proc"
    "/sys"
    "/dev"
    "/run"
  ];
  excludeFlags = lib.concatMapStringsSep " " (p: "--exclude-dir=${p}") (
    systemExcludes ++ cfg.excludePaths
  );

  scanScript = pkgs.writeShellScriptBin "clamav-scan" ''
    case "$1" in
      home)
        TARGET="$HOME"
        sudo clamscan --recursive --move="${quarantine}" ${excludeFlags} "$TARGET"
        ;;
      system)
        sudo clamscan --recursive --move="${quarantine}" ${excludeFlags} /
        ;;
      "")
        echo "Usage: clamav-scan home | system | <path>"
        exit 1
        ;;
      *)
        sudo clamscan --recursive --move="${quarantine}" ${excludeFlags} "$1"
        ;;
    esac
  '';
in
{
  options.features.security.clamav = {
    enable = lib.mkEnableOption "ClamAV on-demand antivirus scanner";
    excludePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Directories excluded from all scans.";
      example = [ "/home/vino/Documents/Projekts/mrijaPage" ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable freshclam (pulls in the clamav package automatically).
    services.clamav.updater.enable = true;

    # Override the recurring timer: fire once 2 minutes after boot instead.
    # mkForce replaces the entire timerConfig set (drops OnCalendar and Persistent).
    systemd.timers.clamav-freshclam.timerConfig = lib.mkForce {
      OnBootSec = "2min";
    };

    # Quarantine directory — root-owned, never auto-cleaned.
    systemd.tmpfiles.rules = [
      "d ${quarantine} 0700 root root -"
    ];

    environment.systemPackages = [ scanScript ];
  };
}
