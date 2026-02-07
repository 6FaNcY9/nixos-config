{
  config,
  pkgs,
  lib,
  ...
}: let
  hasBattery = config.devices.battery != "";
  hasBacklight = config.devices.backlight != "";
  showBattery = hasBattery;
  showBacklight = hasBacklight;
  showPower = hasBattery;
  showIp = !hasBattery;
  modulesLeft = "i3 spacer-tray tray";
  modulesRight = lib.concatStringsSep " " (
    ["host" "network" "pulseaudio"]
    ++ lib.optionals showIp ["ip"]
    ++ lib.optionals showBattery ["battery"]
    ++ lib.optionals showBacklight ["backlight"]
    ++ lib.optionals showPower ["power"]
    ++ ["clock"]
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

      settings."bar/top" = {
        width = "100%";
        height = 26;
        background = "\${colors.background}";
        foreground = "\${colors.foreground}";
        padding = 2;
        module-margin = 0;
        font-0 = "JetBrainsMono Nerd Font:size=11;2";
        font-1 = "Font Awesome 6 Free:style=Solid:pixelsize=11;2";
        font-2 = "Font Awesome 6 Free:style=Regular:pixelsize=11;2";
        font-3 = "Font Awesome 6 Brands:style=Regular:pixelsize=11;2";

        modules-left = modulesLeft;
        modules-center = "xwindow";
        modules-right = modulesRight;
        cursor-click = "pointer";
        enable-ipc = true;
        wm-restack = "i3";
      };
    };
  };
}
