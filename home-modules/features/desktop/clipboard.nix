# Clipboard manager for desktop
{
  lib,
  config,
  ...
}:
let
  cfg = config.features.desktop.clipboard;
in
{
  options.features.desktop.clipboard = {
    enable = lib.mkEnableOption "clipboard manager (clipmenu)";
  };

  config = lib.mkIf cfg.enable {
    services.clipmenu = {
      enable = true;
      launcher = "rofi -dmenu";
    };
  };
}
