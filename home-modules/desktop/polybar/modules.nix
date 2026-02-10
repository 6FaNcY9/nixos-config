{
  config,
  pkgs,
  lib,
  workspaces,
  hostname,
  cfgLib,
  ...
}: let
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
          # Focused: black on yellow
          label-focused = " %icon% ";
          label-focused-foreground = "\${colors.black}";
          label-focused-background = "\${colors.yellow-alt}";
          label-focused-padding = 0;
          # Unfocused: yellow icons on bar bg
          label-unfocused = " %icon% ";
          label-unfocused-foreground = "\${colors.yellow-alt}";
          label-unfocused-padding = 0;
          # Visible (other monitor)
          label-visible = " %icon% ";
          label-visible-foreground = "\${colors.yellow-alt}";
          label-visible-underline = "\${colors.red}";
          label-visible-padding = 0;
          # Urgent
          label-urgent = " %icon% ";
          label-urgent-foreground = "\${colors.black}";
          label-urgent-background = "\${colors.red-alt}";
          label-urgent-padding = 0;
          # Small bullet separators between workspaces
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
      "module/xwindow" = {
        type = "internal/xwindow";
        format-prefix = "  ";
        format-prefix-foreground = "\${colors.black}";
        format-prefix-background = "\${colors.purple}";
        label = "%title:0:50:.....%";
        label-foreground = "\${colors.black}";
        label-background = "\${colors.purple-alt}";
        label-padding-left = 1;
        label-padding-right = 1;
      };

      # ── Time (center, orange two-tone) ──
      "module/time" = {
        type = "internal/date";
        interval = 1;
        format-prefix = "  ";
        format-prefix-foreground = "\${colors.black}";
        format-prefix-background = "\${colors.orange}";
        date = "%H:%M:%S";
        format = "<label>";
        label = "%{A1:${pkgs.gsimplecal}/bin/gsimplecal &:}%date%%{A}";
        label-foreground = "\${colors.black}";
        label-background = "\${colors.orange-alt}";
        label-padding-left = 1;
        label-padding-right = 1;
      };

      # ── Date (center, yellow two-tone) ──
      "module/date" = {
        type = "internal/date";
        interval = 60;
        format-prefix = "  ";
        format-prefix-foreground = "\${colors.black}";
        format-prefix-background = "\${colors.yellow}";
        date = "%d-%m-%Y";
        format = "<label>";
        label = "%date%";
        label-foreground = "\${colors.black}";
        label-background = "\${colors.yellow-alt}";
        label-padding-left = 1;
        label-padding-right = 1;
      };

      # ── Hostname (blue two-tone) ──
      "module/host" = {
        type = "custom/script";
        exec = "echo ${hostname}";
        interval = 3600;
        format-prefix = "  ";
        format-prefix-foreground = "\${colors.black}";
        format-prefix-background = "\${colors.blue}";
        label-foreground = "\${colors.black}";
        label-background = "\${colors.blue-alt}";
        label-padding-left = 1;
        label-padding-right = 1;
      };

      # ── CPU (green two-tone) ──
      "module/cpu" = {
        type = "internal/cpu";
        interval = 1;
        format-prefix = "  ";
        format-prefix-foreground = "\${colors.black}";
        format-prefix-background = "\${colors.green}";
        label = "%percentage:2%%";
        label-foreground = "\${colors.black}";
        label-background = "\${colors.green-alt}";
        label-padding-left = 1;
        label-padding-right = 1;
      };

      # ── Temperature (red two-tone) ──
      "module/temp" = {
        type = "custom/script";
        format-prefix = "  ";
        format-prefix-foreground = "\${colors.black}";
        format-prefix-background = "\${colors.red}";
        exec = "${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gawk}/bin/awk '/^edge/||/^Tctl/ {print $2; exit}' || echo N/A";
        interval = 2;
        label-foreground = "\${colors.black}";
        label-background = "\${colors.red-alt}";
        label-padding-left = 1;
        label-padding-right = 1;
      };

      # ── Memory (orange two-tone) ──
      "module/memory" = {
        type = "internal/memory";
        interval = 1;
        format-prefix = "  ";
        format-prefix-foreground = "\${colors.black}";
        format-prefix-background = "\${colors.orange}";
        label = "%free%";
        label-foreground = "\${colors.black}";
        label-background = "\${colors.orange-alt}";
        label-padding-left = 1;
        label-padding-right = 1;
      };

      # ── Audio (yellow two-tone, muted = red) ──
      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        format-volume-prefix = "  ";
        format-volume-prefix-foreground = "\${colors.black}";
        format-volume-prefix-background = "\${colors.yellow}";
        format-volume = "<label-volume>";
        label-volume = "%percentage%%";
        label-volume-foreground = "\${colors.black}";
        label-volume-background = "\${colors.yellow-alt}";
        label-volume-padding-left = 1;
        label-volume-padding-right = 1;
        format-muted-prefix = "  ";
        format-muted-prefix-foreground = "\${colors.black}";
        format-muted-prefix-background = "\${colors.red}";
        format-muted = "<label-muted>";
        label-muted = "muted";
        label-muted-foreground = "\${colors.black}";
        label-muted-background = "\${colors.red-alt}";
        label-muted-padding-left = 1;
        label-muted-padding-right = 1;
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
      "module/network" = {
        type = "internal/network";
        interface = "${config.devices.networkInterface}";
        interval = 3;
        format-connected-prefix = "  ";
        format-connected-prefix-foreground = "\${colors.black}";
        format-connected-prefix-background = "\${colors.green}";
        format-connected = "<label-connected>";
        label-connected = "%essid%";
        label-connected-foreground = "\${colors.black}";
        label-connected-background = "\${colors.green-alt}";
        label-connected-padding-left = 1;
        label-connected-padding-right = 1;
        format-disconnected-prefix = "  ";
        format-disconnected-prefix-foreground = "\${colors.black}";
        format-disconnected-prefix-background = "\${colors.red}";
        format-disconnected = "<label-disconnected>";
        label-disconnected = "off";
        label-disconnected-foreground = "\${colors.black}";
        label-disconnected-background = "\${colors.red-alt}";
        label-disconnected-padding-left = 1;
        label-disconnected-padding-right = 1;
        click-left = "rofi-network-menu";
        click-right = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor &";
      };
    })

    # ── Battery (aqua two-tone) ──
    (lib.optionalAttrs hasBattery {
      "module/battery" = {
        type = "internal/battery";
        inherit (config.devices) battery;
        full-at = 98;
        format-charging-prefix = "  ";
        format-charging-prefix-foreground = "\${colors.black}";
        format-charging-prefix-background = "\${colors.aqua}";
        format-charging = "<label-charging>";
        label-charging = "%percentage%%";
        label-charging-foreground = "\${colors.black}";
        label-charging-background = "\${colors.aqua-alt}";
        label-charging-padding-left = 1;
        label-charging-padding-right = 1;
        format-discharging-prefix = "  ";
        format-discharging-prefix-foreground = "\${colors.black}";
        format-discharging-prefix-background = "\${colors.aqua}";
        format-discharging = "<label-discharging>";
        label-discharging = "%percentage%%";
        label-discharging-foreground = "\${colors.black}";
        label-discharging-background = "\${colors.aqua-alt}";
        label-discharging-padding-left = 1;
        label-discharging-padding-right = 1;
        format-full-prefix = "  ";
        format-full-prefix-foreground = "\${colors.black}";
        format-full-prefix-background = "\${colors.aqua}";
        format-full = "<label-full>";
        label-full = "100%";
        label-full-foreground = "\${colors.black}";
        label-full-background = "\${colors.aqua-alt}";
        label-full-padding-left = 1;
        label-full-padding-right = 1;
      };
    })
  ];
}
