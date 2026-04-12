# Screen lock module - switches to LightDM greeter on lock
# Uses dm-tool switch-to-greeter for instant lock with the same login screen as boot.
# The i3 session is preserved; logging in returns to it.

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.desktop.lock;

  lockScript = pkgs.writeShellScriptBin "lock-screen" ''
    set -euo pipefail
    ${pkgs.lightdm}/bin/dm-tool switch-to-greeter
  '';
in
{
  options.features.desktop.lock = {
    enable = lib.mkEnableOption "desktop lock screen via LightDM greeter";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ lockScript ];
  };
}
