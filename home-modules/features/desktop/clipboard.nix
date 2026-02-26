# Clipboard manager - Persistent clipboard history with rofi integration
# Uses clipmenu to store clipboard history, rofi as the selection interface
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
