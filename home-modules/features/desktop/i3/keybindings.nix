{
  lib,
  pkgs,
  workspaces,
  cfgLib,
  ...
}: let
  mod = "Mod4";

  # Generate directional focus bindings (j/k/l/; and arrows)
  directionalFocus = cfgLib.mkDirectionalBindings {
    inherit mod;
    command = "focus";
  };

  # Generate directional move bindings (Shift+j/k/l/; and arrows)
  directionalMove = cfgLib.mkDirectionalBindings {
    inherit mod;
    command = "move";
    shift = true;
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
    "${mod}+Return" = "exec alacritty";
    "${mod}+d" = "exec rofi -show drun";
    "${mod}+Shift+q" = "kill";
    "${mod}+Shift+c" = "reload";
    "${mod}+Shift+r" = "restart";
    "${mod}+Shift+x" = "exec ${pkgs.i3lock}/bin/i3lock";
    "${mod}+r" = "mode \"resize\"";

    "Print" = "exec ${pkgs.flameshot}/bin/flameshot gui";

    "XF86AudioRaiseVolume" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
    "XF86AudioLowerVolume" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
    "XF86AudioMute" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";

    "XF86MonBrightnessUp" = "exec --no-startup-id ${pkgs.brightnessctl}/bin/brightnessctl set +10%";
    "XF86MonBrightnessDown" = "exec --no-startup-id ${pkgs.brightnessctl}/bin/brightnessctl set 10%-";

    "XF86AudioPlay" = "exec --no-startup-id ${pkgs.playerctl}/bin/playerctl play-pause";
    "XF86AudioNext" = "exec --no-startup-id ${pkgs.playerctl}/bin/playerctl next";
    "XF86AudioPrev" = "exec --no-startup-id ${pkgs.playerctl}/bin/playerctl previous";
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
in {
  xsession.windowManager.i3.config.keybindings = lib.mkOptionDefault (
    directionalFocus
    // directionalMove
    // layoutBindings
    // systemBindings
    // workspaceSwitch
    // workspaceMove
  );
}
