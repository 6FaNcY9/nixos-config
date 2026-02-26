{
  lib,
  pkgs,
  workspaces,
  cfgLib,
  ...
}:
let
  mod = "Mod4";
  execMediaKey = cmd: "exec --no-startup-id ${cmd}";
  pactl = "${pkgs.pulseaudio}/bin/pactl";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";

  directionalFocus = {
    "${mod}+j" = "focus left";
    "${mod}+k" = "focus down";
    "${mod}+l" = "focus up";
    "${mod}+semicolon" = "focus right";
    "${mod}+Left" = "focus left";
    "${mod}+Down" = "focus down";
    "${mod}+Up" = "focus up";
    "${mod}+Right" = "focus right";
  };

  directionalMove = {
    "${mod}+Shift+j" = "move left";
    "${mod}+Shift+k" = "move down";
    "${mod}+Shift+l" = "move up";
    "${mod}+Shift+semicolon" = "move right";
    "${mod}+Shift+Left" = "move left";
    "${mod}+Shift+Down" = "move down";
    "${mod}+Shift+Up" = "move up";
    "${mod}+Shift+Right" = "move right";
  };

  layoutBindings = {
    "${mod}+h" = "split horizontal";
    "${mod}+v" = "split vertical";
    "${mod}+e" = "layout toggle split";
    "${mod}+s" = "layout stacking";
    "${mod}+w" = "layout tabbed";
    "${mod}+f" = "fullscreen toggle";
    "${mod}+space" = "focus mode_toggle";
    "${mod}+Shift+space" = "floating toggle";
    "${mod}+a" = "focus parent";
    "${mod}+Shift+a" = "focus child";
  };

  systemBindings = {
    # Scratchpad
    "${mod}+m" = "move scratchpad";
    "${mod}+Shift+m" = "scratchpad show";

    "${mod}+Return" = "exec alacritty";
    "${mod}+d" = "exec rofi -show drun";
    "${mod}+Shift+q" = "kill";
    "${mod}+Shift+c" = "reload";
    "${mod}+Shift+r" = "restart";
    "${mod}+Shift+x" = "exec lock-screen";
    "${mod}+r" = "mode \"resize\"";

    "Print" = "exec ${pkgs.flameshot}/bin/flameshot gui";

    # Dunst notification controls
    "${mod}+grave" = "exec ${pkgs.dunst}/bin/dunstctl history-pop";
    "${mod}+Shift+d" = "exec ${pkgs.dunst}/bin/dunstctl set-paused toggle";
    "${mod}+Shift+period" = "exec ${pkgs.dunst}/bin/dunstctl close-all";
  };

  mediaKeys = {
    "XF86AudioRaiseVolume" = execMediaKey "${pactl} set-sink-volume @DEFAULT_SINK@ +5%";
    "XF86AudioLowerVolume" = execMediaKey "${pactl} set-sink-volume @DEFAULT_SINK@ -5%";
    "XF86AudioMute" = execMediaKey "${pactl} set-sink-mute @DEFAULT_SINK@ toggle";
    "XF86MonBrightnessUp" = execMediaKey "${brightnessctl} set +10%";
    "XF86MonBrightnessDown" = execMediaKey "${brightnessctl} set 10%-";
    "XF86AudioPlay" = execMediaKey "${playerctl} play-pause";
    "XF86AudioNext" = execMediaKey "${playerctl} next";
    "XF86AudioPrev" = execMediaKey "${playerctl} previous";
  };

  workspaceSwitch = cfgLib.mkWorkspaceBindings {
    inherit mod workspaces;
    commandPrefix = "workspace";
  };

  workspaceMove = cfgLib.mkWorkspaceBindings {
    inherit mod workspaces;
    commandPrefix = "move container to workspace";
    shift = true;
  };
in
{
  xsession.windowManager.i3.config.keybindings = lib.mkOptionDefault (
    directionalFocus
    // directionalMove
    // layoutBindings
    // systemBindings
    // mediaKeys
    // workspaceSwitch
    // workspaceMove
  );
}
