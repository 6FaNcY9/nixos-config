{
  lib,
  pkgs,
  c,
  i3Pkg,
  workspaces,
  ...
}: {
  xsession = {
    enable = true;

    windowManager.i3 = {
      enable = true;
      package = i3Pkg;

      config = let
        cfgLib = import ../../lib {inherit lib;};
        mod = "Mod4";
        workspaceNames = map (workspace: workspace.name) workspaces;

        workspaceSwitch = cfgLib.mkWorkspaceBindings {
          inherit mod;
          workspaces = workspaceNames;
          commandPrefix = "workspace";
        };

        workspaceMove = cfgLib.mkWorkspaceBindings {
          inherit mod;
          workspaces = workspaceNames;
          commandPrefix = "move container to workspace";
          shift = true;
        };
      in {
        modifier = mod;
        terminal = "alacritty";
        menu = "rofi -show drun";

        gaps = {
          inner = 10;
          outer = 0;
          smartGaps = false;
          smartBorders = "on";
        };

        window = {
          border = 3;
          titlebar = false;
        };

        colors = lib.mkForce {
          focused = {
            border = c.base0A;
            background = c.base01;
            text = c.base07;
            indicator = c.base0A;
            childBorder = c.base0A;
          };

          focusedInactive = {
            border = c.base03;
            background = c.base00;
            text = c.base05;
            indicator = c.base03;
            childBorder = c.base03;
          };

          unfocused = {
            border = c.base02;
            background = c.base00;
            text = c.base04;
            indicator = c.base02;
            childBorder = c.base02;
          };

          urgent = {
            border = c.base08;
            background = c.base00;
            text = c.base07;
            indicator = c.base08;
            childBorder = c.base08;
          };
        };

        workspaceAutoBackAndForth = true;

        startup = [
          {
            command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
            notification = false;
          }
          {
            command = "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock --ignore-sleep ${pkgs.i3lock}/bin/i3lock";
            notification = false;
          }
          {
            command = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
            notification = false;
          }
          {
            command = "${pkgs.blueman}/bin/blueman-applet";
            notification = false;
          }
          #{ command = "${pkgs.polybar}/bin/polybar --reload top"; notification = false; }
          #{ command = "${pkgs.feh}/bin/feh "; notification = false; }
        ];

        assigns = {
          "${builtins.elemAt workspaceNames 0}" = [{class = "firefox";} {class = "Firefox";}];
          "${builtins.elemAt workspaceNames 1}" = [{class = "Alacritty";}];
          "${builtins.elemAt workspaceNames 2}" = [{class = "Code";}];
          "${builtins.elemAt workspaceNames 3}" = [{class = "Thunar";}];
        };

        # bars = [
        #   ({
        #     position = "top";
        #     statusCommand = "${pkgs.i3blocks}/bin/i3blocks -c ${config.xdg.configHome}/i3blocks/top";
        #
        #     colors = {
        #       background = c.base00;
        #       statusline = c.base05;
        #       separator = c.base03;
        #
        #       focusedWorkspace = {
        #         border = c.base0A;
        #         background = c.base01;
        #         text = c.base07;
        #       };
        #
        #       activeWorkspace = {
        #         border = c.base03;
        #         background = c.base00;
        #         text = c.base05;
        #       };
        #
        #       inactiveWorkspace = {
        #         border = c.base02;
        #         background = c.base00;
        #         text = c.base04;
        #       };
        #
        #       urgentWorkspace = {
        #         border = c.base08;
        #         background = c.base00;
        #         text = c.base07;
        #       };
        #
        #       bindingMode = {
        #         border = c.base09;
        #         background = c.base00;
        #         text = c.base07;
        #       };
        #     };
        #   } // config.stylix.targets.i3.exportedBarConfig)
        #];

        # Polybar is started by Home Manager (programs.polybar); no i3 bar needed here.
        bars = lib.mkForce [];

        keybindings = lib.mkOptionDefault (
          let
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
              "${mod}+Return" = "exec alacritty";
              "${mod}+d" = "exec rofi -show drun";
              "${mod}+Shift+q" = "kill";
              "${mod}+Shift+c" = "reload";
              "${mod}+Shift+r" = "restart";
              "${mod}+Shift+x" = "exec ${pkgs.i3lock}/bin/i3lock";
              "${mod}+Shift+z" = "exec systemctl suspend";
              "${mod}+Shift+b" = "exec systemctl reboot";
              "${mod}+Shift+p" = "exec systemctl poweroff";
              "${mod}+Shift+e" = "exec i3-nagbar -t warning -m 'Exit session?' -b 'Yes' 'xfce4-session-logout'";
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
          in
            directionalFocus
            // directionalMove
            // layoutBindings
            // systemBindings
            // workspaceSwitch
            // workspaceMove
        );

        modes = lib.mkOptionDefault {
          resize = {
            "h" = "resize shrink width 10 px or 10 ppt";
            "j" = "resize grow height 10 px or 10 ppt";
            "k" = "resize shrink height 10 px or 10 ppt";
            "l" = "resize grow width 10 px or 10 ppt";
            "Left" = "resize shrink width 10 px or 10 ppt";
            "Down" = "resize grow height 10 px or 10 ppt";
            "Up" = "resize shrink height 10 px or 10 ppt";
            "Right" = "resize grow width 10 px or 10 ppt";
            "Return" = "mode default";
            "Escape" = "mode default";
          };
        };
      };
    };
  };
}
