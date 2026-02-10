{
  config,
  pkgs,
  lib,
  ...
}: let
  hasBattery = config.devices.battery != "";
  hasNetwork = config.devices.networkInterface != "";
  modulesLeft = "menu i3 xwindow tray";
  modulesCenter = "time date";
  modulesRight = lib.concatStringsSep " " (
    ["host" "cpu" "temp" "memory"]
    ++ lib.optionals hasNetwork ["network"]
    ++ ["pulseaudio"]
    ++ lib.optionals hasBattery ["battery"]
    ++ ["power"]
  );
in {
  imports = [
    ./colors.nix
    ./modules.nix
  ];

  config = lib.mkIf config.profiles.desktop {
    services.polybar = {
      enable = true;
      package = pkgs.polybar.override {
        i3Support = true;
        pulseSupport = true;
        iwSupport = true;
      };

      script = ''
        ${pkgs.procps}/bin/pkill -x polybar || true
        ${config.services.polybar.package}/bin/polybar --reload top &
      '';

      settings = {
        "bar/top" = {
          width = "100%";
          height = "16pt";
          radius = 0;
          dpi = 100;
          background = "\${colors.dark}";
          foreground = "\${colors.muted}";
          padding = 0;
          module-margin = 0;
          line-size = "0pt";
          border-size = "3pt";
          border-color = "\${colors.dark}";
          separator = ".";
          separator-foreground = "\${colors.transparent}";
          font-0 = "Iosevka Term:size=11.5:weight=bold;2"; # Plain (no NerdFont) — no FA6 icon conflict
          font-1 = "Font Awesome 6 Free Solid:pixelsize=12;3"; # Proportional icons
          font-2 = "Font Awesome 6 Free:pixelsize=12;3";
          font-3 = "Font Awesome 6 Brands:pixelsize=12;3";
          modules-left = modulesLeft;
          modules-center = modulesCenter;
          modules-right = modulesRight;
          cursor-click = "pointer";
          enable-ipc = true;
          tray-position = "none";
        };
        "settings" = {
          screenchange-reload = true;
          pseudo-transparency = true;
        };
      };
    };
  };
}
