{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.features.desktop.polybar;
  hasBattery = config.devices.battery != "";
  hasNetwork = config.devices.networkInterface != "";
  modulesLeft = "menu i3 xwindow tray";
  modulesCenter = "time";
  modulesRight = lib.concatStringsSep " " (
    [
      "host"
      "cpu"
      "temp"
      "memory"
    ]
    ++ lib.optionals hasNetwork [ "network" ]
    ++ lib.optionals hasBattery [ "battery" ]
    ++ [ "power" ]
  );
in
{
  imports = [
    ./colors.nix
    ./modules.nix
  ];

  options.features.desktop.polybar = {
    enable = lib.mkEnableOption "Polybar status bar with custom configuration";
  };

  config = lib.mkIf cfg.enable {
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
          font-0 = "Iosevka Term:size=11.5:weight=bold;2"; # Plain text
          font-1 = "Symbols Nerd Font Mono:size=14;3"; # Monospaced icons (nerd-fonts.symbols-only)
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
