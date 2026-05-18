# Screen lock module for the i3 desktop.
# Uses i3lock so locking stays independent from the active display manager.

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.desktop.lock;

  lockScript = pkgs.writeShellScriptBin "lock-screen" ''
    exec ${pkgs.i3lock}/bin/i3lock -c 000000
  '';
in
{
  options.features.desktop.lock = {
    enable = lib.mkEnableOption "desktop lock screen via i3lock";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ lockScript ];
  };
}
