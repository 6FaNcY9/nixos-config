# Polybar status bar module
# Top bar with i3 workspaces, window title, system stats, time, tray
# Font choices:
# - font-0 (stylixFonts.monospace): Primary text, size 14pt bold
# - font-1 (Symbols Nerd Font): Icons from nerd-fonts symbols-only package

{
  config,
  pkgs,
  lib,
  stylixFonts ? {
    monospace.name = "Monospace";
  },
  ...
}:
let
  cfg = config.features.desktop.polybar;
  hasBattery = config.devices.battery != "";
  hasNetwork = config.devices.networkInterface != "";
  hasLan = config.devices.lanInterface != "";
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
    ++ lib.optionals hasLan [ "lan" ]
    ++ lib.optionals hasBattery [ "battery" ]
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
        # Wait for i3 socket — polybar starts before i3 is ready at login,
        # causing the i3 module to be silently disabled for the whole session.
        until I3SOCK=$(${pkgs.i3}/bin/i3 --get-socketpath 2>/dev/null); do
          ${pkgs.coreutils}/bin/sleep 0.5
        done
        export I3SOCK
        ${config.services.polybar.package}/bin/polybar --reload top &
      '';

      settings = {
        "bar/top" = {
          width = "calc(100% - 10px)";
          offset-x = 5;
          offset-y = 5;
          height = "18pt";
          radius = 8;
          dpi = 100;
          background = "\${colors.dark}";
          foreground = "\${colors.muted}";
          padding = 0;
          module-margin = 2;
          line-size = "0pt";
          font-0 = "${stylixFonts.monospace.name}:size=14:weight=bold;2";
          font-1 = "Symbols Nerd Font Mono:size=14;3";
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
