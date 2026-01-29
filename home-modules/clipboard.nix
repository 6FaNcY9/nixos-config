# Clipboard manager for desktop
{
  lib,
  config,
  pkgs,
  ...
}: {
  options.clipboard = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.profiles.desktop;
      description = "Enable clipboard manager (auto-enabled with desktop profile).";
    };

    manager = lib.mkOption {
      type = lib.types.enum ["clipmenu" "parcellite"];
      default = "clipmenu";
      description = "Which clipboard manager to use.";
    };
  };

  config = lib.mkIf config.clipboard.enable {
    # Clipboard manager service
    services.clipmenu = lib.mkIf (config.clipboard.manager == "clipmenu") {
      enable = true;
      launcher = "rofi -dmenu";
    };

    # Alternative: parcellite (GTK-based)
    home.packages = lib.mkIf (config.clipboard.manager == "parcellite") [
      pkgs.parcellite
    ];

    # Autostart parcellite if selected
    xdg.configFile."autostart/parcellite.desktop" = lib.mkIf (config.clipboard.manager == "parcellite") {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Parcellite
        Exec=${pkgs.parcellite}/bin/parcellite
        Hidden=false
        NoDisplay=false
        X-GNOME-Autostart-enabled=true
      '';
    };
  };
}
