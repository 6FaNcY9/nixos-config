{
  lib,
  pkgs,
  c,
  i3Pkg,
  workspaces,
  config,
  ...
}: {
  config = lib.mkIf config.profiles.desktop {
    xsession = {
      enable = true;

      windowManager.i3 = {
        enable = true;
        package = i3Pkg;

        config = let
          cfgLib = import ../lib {inherit lib;};
          mod = "Mod4";

          wsName = n: cfgLib.mkWorkspaceName (builtins.elemAt workspaces (n - 1));
          assignRules = [
            {
              ws = 1;
              criteria = [{class = "firefox";}];
            }
            {
              ws = 2;
              criteria = [{class = "Alacritty";}]; # Fixed: Capitalized
            }
            {
              ws = 3;
              criteria = [{class = "Code";}]; # Fixed: Capitalized
            }
            {
              ws = 4;
              criteria = [{class = "Thunar";}];
            }
            {
              ws = 5;
              criteria = [{class = "Spotify";}];
            }
            {
              ws = 6;
              criteria = [{class = "feh";}];
            }
            #{ ws = 7; criteria = [{ class = "Gaming"; }]; }
            {
              ws = 8;
              criteria = [{class = "discord";}]; # Note: Discord might be capitalized too
            }
            {
              ws = 9;
              criteria = [{class = "xfce4-settings-manager";}];
            }
          ];

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
              command = "${pkgs.blueman}/bin/blueman-applet";
              notification = false;
            }
          ];

          bars = lib.mkForce [];

          assigns = builtins.listToAttrs (map (r: {
              name = wsName r.ws;
              value = r.criteria;
            })
            assignRules);

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
  };
}
