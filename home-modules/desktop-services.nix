# Desktop session services: dunst, picom, flameshot, network-manager-applet
{
  lib,
  pkgs,
  config,
  c,
  ...
}: {
  config = lib.mkIf config.profiles.desktop {
    services = {
      network-manager-applet.enable = true;
      dunst.enable = true;
      picom.enable = true;

      flameshot = {
        enable = true;
        package = pkgs.flameshot;
        settings = {
          General = {
            uiColor = c.base01;
            drawColor = c.base0B;
            showSidePanelButton = true;
            showDesktopNotification = false;
            disabledTrayIcon = false;
          };
          Shortcuts = {
            TYPE_COPY = "Return";
            TYPE_SAVE = "Ctrl+S";
          };
        };
      };
    };
  };
}
