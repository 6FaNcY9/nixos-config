# Rofi menu scripts (power, network, clipboard, audio, dropdown).
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.features.desktop.rofi;

  powerMenu = pkgs.writeShellApplication {
    name = "rofi-power-menu";
    runtimeInputs = [ pkgs.rofi ];
    text = builtins.readFile ./scripts/power-menu.sh;
  };

  networkMenu = pkgs.writeShellApplication {
    name = "rofi-network-menu";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.iproute2
      pkgs.libnotify
      pkgs.networkmanager
      pkgs.networkmanagerapplet
      pkgs.rofi
    ];
    text = builtins.readFile ./scripts/network-menu.sh;
  };

  clipboardMenu = pkgs.writeShellApplication {
    name = "rofi-clipboard-menu";
    runtimeInputs = [
      pkgs.clipmenu
      pkgs.rofi
    ];
    text = builtins.readFile ./scripts/clipboard-menu.sh;
  };

  audioSwitcher = pkgs.writeShellApplication {
    name = "rofi-audio-switcher";
    runtimeInputs = [
      pkgs.gnugrep
      pkgs.gnused
      pkgs.libnotify
      pkgs.pulseaudio
      pkgs.rofi
    ];
    text = builtins.readFile ./scripts/audio-switcher.sh;
  };

  dropdownMenu = pkgs.writeShellApplication {
    name = "rofi-dropdown-menu";
    runtimeInputs = [
      audioSwitcher
      pkgs.autotiling
      pkgs.brightnessctl
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.gnused
      pkgs.libnotify
      pkgs.playerctl
      pkgs.procps
      pkgs.pulseaudio
      pkgs.rofi
    ];
    text = builtins.readFile ./scripts/dropdown-menu.sh;
  };
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      audioSwitcher
      clipboardMenu
      dropdownMenu
      networkMenu
      powerMenu
    ];

    services.polybar.settings = {
      "module/menu".click-left = "exec ${dropdownMenu}/bin/rofi-dropdown-menu &";
      "module/power".click-left = "exec ${powerMenu}/bin/rofi-power-menu";
      "module/network".click-left = "${networkMenu}/bin/rofi-network-menu";
    };

    xsession.windowManager.i3.config.keybindings =
      let
        mod = config.xsession.windowManager.i3.config.modifier;
      in
      lib.mkOptionDefault {
        "${mod}+Shift+e" = "exec ${powerMenu}/bin/rofi-power-menu";
        "${mod}+Shift+v" = "exec ${clipboardMenu}/bin/rofi-clipboard-menu";
        "${mod}+Shift+n" = "exec ${networkMenu}/bin/rofi-network-menu";
        "${mod}+Shift+s" = "exec ${audioSwitcher}/bin/rofi-audio-switcher";
      };
  };
}
