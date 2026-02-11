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
  hasNetwork = config.devices.networkInterface != "";
in {
  services.polybar.settings = lib.mkMerge [
    {
      # ── MENU button ──
      "module/menu" = {
        type = "custom/text";
        format = " MENU ";
        click-left = "exec rofi -show drun -disable-history -show-icons &";
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
          label-separator = "•";
          label-separator-padding = 1;
          label-separator-foreground = "\${colors.yellow-alt}";
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
          icon = "";
          color = "purple";
        };

      # ── Time (center, orange two-tone) ──
      "module/time" =
        {
          type = "internal/date";
          interval = 1;
          date = "%H:%M:%S";
          format = "<label>";
          label = "%{A1:${pkgs.gsimplecal}/bin/gsimplecal &:}%date%%{A}";
        }
        // mkPolybarTwoTone {
          icon = "";
          color = "orange";
        };

      # ── Date (center, yellow two-tone) ──
      "module/date" =
        {
          type = "internal/date";
          interval = 60;
          date = "%d-%m-%Y";
          format = "<label>";
          label = "%date%";
        }
        // mkPolybarTwoTone {
          icon = "";
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
          icon = "";
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
          icon = "";
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
          icon = "";
          color = "red";
        };

      # ── Memory (orange two-tone) ──
      "module/memory" =
        {
          type = "internal/memory";
          interval = 1;
          label = "%free%";
        }
        // mkPolybarTwoTone {
          icon = "";
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
          icon = "";
          color = "yellow";
        }
        // mkPolybarTwoToneState {
          state = "muted";
          icon = "";
          color = "red";
        };

      # ── Power button (yellow block) ──
      "module/power" = {
        type = "custom/text";
        format = "  ";
        click-left = "exec rofi-power-menu";
        format-foreground = "\${colors.black}";
        format-background = "\${colors.yellow}";
      };
    }

    # ── Network / WiFi (green two-tone) ──
    (lib.optionalAttrs hasNetwork {
      "module/network" =
        {
          type = "internal/network";
          interface = "${config.devices.networkInterface}";
          interval = 3;
          label-connected = "%essid%";
          label-disconnected = "off";
          click-left = "rofi-network-menu";
          click-right = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor &";
        }
        // mkPolybarTwoToneState {
          state = "connected";
          icon = "";
          color = "green";
        }
        // mkPolybarTwoToneState {
          state = "disconnected";
          icon = "睊";
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
          icon = "";
          color = "aqua";
        }
        // mkPolybarTwoToneState {
          state = "discharging";
          icon = "";
          color = "aqua";
        }
        // mkPolybarTwoToneState {
          state = "full";
          icon = "";
          color = "aqua";
        };
    })
  ];
}
