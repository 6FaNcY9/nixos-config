# Security: ClamAV on-demand antivirus scanner
#
# Provides commands via wrapper scripts:
#   clamav-scan home    — scans $HOME
#   clamav-scan system  — scans /
#   clamav-scan <path>  — scans a specific path
#   clamav-update       — manually update virus definitions (run freshclam)
#
# Virus definitions are NOT updated automatically — run clamav-update manually.
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

  updateScript = pkgs.writeShellScriptBin "clamav-update" ''
    echo "Updating ClamAV virus definitions..."
    sudo freshclam
  '';

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
    # Install clamav for clamscan and freshclam binaries.
    # The auto-updater (freshclam timer) is intentionally disabled — use clamav-update manually.
    environment.systemPackages = [
      pkgs.clamav
      scanScript
      updateScript
    ];

    # Quarantine directory — root-owned, never auto-cleaned.
    systemd.tmpfiles.rules = [
      "d ${quarantine} 0700 root root -"
    ];
  };
}
