{
  config,
  pkgs,
  lib,
  workspaces,
  hostname,
  cfgLib,
  ...
}: let
  inherit (cfgLib) mkPolybarTwoTone mkPolybarTwoToneState;
  hasIcons = builtins.any (workspace: workspace.icon != "") workspaces;
  wsIconAttrs = lib.listToAttrs (
    map (workspace: {
      name = "ws-icon-${toString (workspace.number - 1)}";
      value = "${cfgLib.mkWorkspaceName workspace};${workspace.icon}";
    })
    workspaces
  );
  hasBattery = config.devices.battery != "";
  hasBacklight = config.devices.backlight != "";
  hasNetwork = config.devices.networkInterface != "";
in {
  services.polybar.settings = lib.mkMerge [
    {
      # ── MENU button (opens dropdown with brightness, now-playing, volume, autotiling) ──
      "module/menu" = {
        type = "custom/text";
        format = " MENU ";
        click-right = "exec ${pkgs.rofi}/bin/rofi -show drun -disable-history -show-icons &";
        format-foreground = "\${colors.black}";
        format-background = "\${colors.orange-alt}";
      };

      # ── i3 workspaces ──
      "module/i3" =
        {
          type = "internal/i3";
          enable-scroll = false;
          pin-workspaces = true;
          show-urgent = true;
          strip-wsnumbers = hasIcons;
          index-sort = true;
          enable-click = true;
          fuzzy-match = true;
          ws-icon-default = "";
          format = "<label-state><label-mode>";
          label-mode = " %mode% ";
          label-mode-padding = 1;
          label-mode-background = "\${colors.red}";
          label-mode-foreground = "\${colors.cream}";
          label-focused = " %icon% ";
          label-focused-foreground = "\${colors.black}";
          label-focused-background = "\${colors.yellow-alt}";
          label-focused-padding = 0;
          label-unfocused = " %icon% ";
          label-unfocused-foreground = "\${colors.yellow-alt}";
          label-unfocused-padding = 0;
          label-visible = " %icon% ";
          label-visible-foreground = "\${colors.yellow-alt}";
          label-visible-underline = "\${colors.red}";
          label-visible-padding = 0;
          label-urgent = " %icon% ";
          label-urgent-foreground = "\${colors.black}";
          label-urgent-background = "\${colors.red-alt}";
          label-urgent-padding = 0;
          label-separator = " ";
          label-separator-padding = 0;
        }
        // wsIconAttrs;

      # ── Tray ──
      "module/tray" = {
        type = "internal/tray";
        format = "<tray>";
        format-background = "\${colors.dark}";
        tray-padding = 2;
        tray-size = 14;
        tray-background = "\${colors.dark}";
      };

      # ── Window title (purple two-tone) ──
      "module/xwindow" =
        {
          type = "internal/xwindow";
          label = "%title:0:50:.....%";
        }
        // mkPolybarTwoTone {
          icon = "󰇣 ";
          color = "purple";
        };

      # ── Time + Date (center, yellow two-tone, merged block) ──
      "module/time" =
        {
          type = "internal/date";
          interval = 1;
          time = "%H:%M:%S";
          date = "%d-%m-%Y";
          format = "<label>";
          label = "%{A1:${pkgs.gsimplecal}/bin/gsimplecal &:}%time%  ||  %date%%{A}";
        }
        // mkPolybarTwoTone {
          icon = "󰃭 ";
          color = "yellow";
        };

      # ── Hostname (blue two-tone) ──
      "module/host" =
        {
          type = "custom/script";
          exec = "echo ${hostname}";
          interval = 3600;
        }
        // mkPolybarTwoTone {
          icon = "󱩊 ";
          color = "blue";
        };

      # ── CPU (green two-tone) ──
      "module/cpu" =
        {
          type = "internal/cpu";
          interval = 1;
          label = "%percentage:2%%";
        }
        // mkPolybarTwoTone {
          icon = " ";
          color = "green";
        };

      # ── Temperature (red two-tone) ──
      "module/temp" =
        {
          type = "custom/script";
          exec = "${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gawk}/bin/awk '/^edge/||/^Tctl/ {print $2; exit}' || echo N/A";
          interval = 2;
        }
        // mkPolybarTwoTone {
          icon = " ";
          color = "red";
        };

      # ── Memory (aqua two-tone) ──
      "module/memory" =
        {
          type = "internal/memory";
          interval = 1;
          label = "%free%";
        }
        // mkPolybarTwoTone {
          icon = "󰍛 ";
          color = "orange";
        };

      # ── Audio (yellow two-tone, muted = red) ──
      "module/pulseaudio" =
        {
          type = "internal/pulseaudio";
          label-volume = "%percentage%%";
          label-muted = "muted";
        }
        // mkPolybarTwoToneState {
          state = "volume";
          icon = "󰕾";
          color = "yellow";
        }
        // mkPolybarTwoToneState {
          state = "muted";
          icon = "󰖁";
          color = "red";
        };

      # ── Power button (yellow block) ──
      "module/power" = {
        type = "custom/text";
        format = " 󰐥 ";
        format-foreground = "\${colors.black}";
        format-background = "\${colors.yellow}";
      };

      # ── Now-Playing (custom script) ──
      "module/now-playing" = {
        type = "custom/script";
        exec = "${pkgs.writeShellScript "polybar-now-playing" ''
          player_status=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null)
          if [ "$player_status" = "Playing" ]; then
            title=$(${pkgs.playerctl}/bin/playerctl metadata title 2>/dev/null | cut -c1-30)
            artist=$(${pkgs.playerctl}/bin/playerctl metadata artist 2>/dev/null | cut -c1-20)
            if [ -n "$title" ]; then
              echo " $artist - $title"
            fi
          elif [ "$player_status" = "Paused" ]; then
            title=$(${pkgs.playerctl}/bin/playerctl metadata title 2>/dev/null | cut -c1-30)
            echo " $title"
          fi
        ''}";
        interval = 3;
        click-left = "${pkgs.playerctl}/bin/playerctl play-pause";
        click-right = "${pkgs.playerctl}/bin/playerctl next";
        format = "<label>";
        label = "%output%";
        label-foreground = "\${colors.cream}";
        format-background = "\${colors.bg}";
        format-padding = 1;
      };

      # ── Autotiling Indicator (aqua two-tone) ──
      "module/autotiling" =
        {
          type = "custom/script";
          exec = "${pkgs.writeShellScript "polybar-autotiling" ''
            if ${pkgs.procps}/bin/pgrep -f autotiling > /dev/null; then
              echo "on"
            else
              echo "off"
            fi
          ''}";
          interval = 5;
          click-left = "${pkgs.writeShellScript "toggle-autotiling" ''
            if ${pkgs.procps}/bin/pgrep -f autotiling > /dev/null; then
              ${pkgs.procps}/bin/pkill -f autotiling
            else
              ${pkgs.autotiling}/bin/autotiling &
            fi
          ''}";
        }
        // mkPolybarTwoTone {
          icon = "󰕭 ";
          color = "aqua";
        };
    }

    # ── Brightness (purple two-tone) ──
    (lib.optionalAttrs hasBacklight {
      "module/brightness" =
        {
          type = "internal/backlight";
          card = config.devices.backlight;
          enable-scroll = true;
        }
        // mkPolybarTwoTone {
          icon = "";
          color = "purple";
        };
    })

    # ── Network / WiFi (green two-tone) ──
    (lib.optionalAttrs hasNetwork {
      "module/network" =
        {
          type = "internal/network";
          interface = "${config.devices.networkInterface}";
          interval = 3;
          label-connected = "%essid%";
          label-disconnected = "off";
          click-right = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor &";
        }
        // mkPolybarTwoToneState {
          state = "connected";
          icon = "󰖩 ";
          color = "green";
        }
        // mkPolybarTwoToneState {
          state = "disconnected";
          icon = "󰖪 ";
          color = "red";
        };
    })

    # ── Battery (aqua two-tone) ──
    (lib.optionalAttrs hasBattery {
      "module/battery" =
        {
          type = "internal/battery";
          inherit (config.devices) battery;
          full-at = 98;
          label-charging = "%percentage%%";
          label-discharging = "%percentage%%";
          label-full = "100%";
        }
        // mkPolybarTwoToneState {
          state = "charging";
          icon = "󰂄";
          color = "aqua";
        }
        // mkPolybarTwoToneState {
          state = "discharging";
          icon = "󰂎";
          color = "aqua";
        }
        // mkPolybarTwoToneState {
          state = "full";
          icon = "󰁹";
          color = "aqua";
        };
    })
  ];
}
