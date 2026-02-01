# Module: security/apparmor.nix
# Purpose: AppArmor confinement controls (opt-in)
#
# Notes:
# - Disabled by default (profiles may need tuning)
# - Enable only when ready to handle profile adjustments
{
  lib,
  pkgs,
  config,
  ...
}: {
  options.security.hardening.apparmor = {
    enable = lib.mkEnableOption "AppArmor confinement";
  };

  config = lib.mkIf config.security.hardening.apparmor.enable {
    security.apparmor = {
      enable = true;
      packages = [pkgs.apparmor-profiles];
    };
  };
}
