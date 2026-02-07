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
  hasBacklight = config.devices.backlight != "";
  hasNetwork = config.devices.networkInterface != "";
  showBattery = hasBattery;
  showBacklight = hasBacklight;
  showPower = hasBattery;
  showIp = !hasBattery;
in {
  services.polybar.settings = lib.mkMerge [
    {
      "module/i3" =
        {
          type = "internal/i3";
          format = "<label-state>";
          index-sort = true;
          pin-workspaces = true;
          strip-wsnumbers = hasIcons;
          ws-icon-default = "";
          label-separator = " ";
          label-focused = "%icon%";
          label-focused-foreground = "\${colors.background}";
          label-focused-background = "\${colors.accent2}";
          label-focused-padding = 1;
          label-unfocused = "%icon%";
          label-unfocused-foreground = "\${colors.foreground}";
          label-unfocused-background = "\${colors.background-alt}";
          label-unfocused-padding = 1;
          label-visible = "%icon%";
          label-visible-foreground = "\${colors.foreground}";
          label-visible-background = "\${colors.background-alt}";
          label-visible-padding = 1;
          label-urgent = "%icon%";
          label-urgent-foreground = "\${colors.background}";
          label-urgent-background = "\${colors.danger}";
          label-urgent-padding = 1;
        }
        // wsIconAttrs;

      # Host module - using laptop icon
      "module/host" = {
        type = "custom/text";
        format = "󰌢  ${hostname}";
        format-foreground = "\${colors.accent2}";
        format-background = "\${colors.background-alt}";
        format-padding = 1;
      };

      "module/xwindow" = {
        type = "internal/xwindow";
        label = "%title:0:60:...%";
        label-background = "\${colors.background-alt}";
        label-padding = 1;
      };

      # Audio - using Material Design volume icons
      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        format-volume = "<label-volume>";
        label-volume = "󰕾 %percentage%%";
        label-volume-background = "\${colors.background-alt}";
        label-volume-foreground = "\${colors.foreground}";
        label-volume-padding = 1;
        label-muted = "󰖁 mute";
        label-muted-foreground = "\${colors.danger}";
        label-muted-background = "\${colors.background-alt}";
        label-muted-padding = 1;
      };

      # Clock - using clock outline icon
      "module/clock" = {
        type = "internal/date";
        interval = 5;
        date = "%H:%M";
        format = "<label>";
        label = "%{A1:${pkgs.gsimplecal}/bin/gsimplecal &:}󰥔 %date%%{A}";
        label-foreground = "\${colors.accent2}";
        label-background = "\${colors.background-alt}";
        label-padding = 1;
      };

      "module/tray" = {
        type = "internal/tray";
        format = "<tray>";
        format-background = "\${colors.background-alt}";
        format-padding = 1;
        tray-padding = 2;
        tray-size = 18;
        tray-background = "\${colors.background-alt}";
      };

      "module/spacer-tray" = {
        type = "custom/text";
        format = " ";
        format-background = "\${colors.background}";
        format-padding = 1;
      };
    }

    # Network - using Material Design wifi icons
    (lib.optionalAttrs hasNetwork {
      "module/network" = {
        type = "internal/network";
        interface = "${config.devices.networkInterface}";
        interval = 3;
        format-connected = "<label-connected>";
        label-connected = "󰖩 %essid%";
        label-connected-background = "\${colors.background-alt}";
        label-connected-foreground = "\${colors.accent}";
        format-disconnected = "<label-disconnected>";
        label-disconnected = "󰖪 offline";
        label-disconnected-background = "\${colors.background-alt}";
        label-disconnected-foreground = "\${colors.danger}";
        label-connected-padding = 1;
        label-disconnected-padding = 1;
        click-left = "rofi-network-menu";
        click-right = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor &";
      };
    })

    # Battery - using Material Design battery icons
    (lib.optionalAttrs showBattery {
      "module/battery" = {
        type = "internal/battery";
        inherit (config.devices) battery;
        full-at = 98;
        format-charging = "<label-charging>";
        format-discharging = "<label-discharging>";
        format-full = "<label-full>";
        label-charging = "󰂄 %percentage%%";
        label-discharging = "󰁹 %percentage%%";
        label-full = "󰁹 100%";
        label-charging-background = "\${colors.background-alt}";
        label-discharging-background = "\${colors.background-alt}";
        label-full-background = "\${colors.background-alt}";
        label-charging-foreground = "\${colors.accent2}";
        label-discharging-foreground = "\${colors.foreground}";
        label-full-foreground = "\${colors.accent2}";
        label-charging-padding = 1;
        label-discharging-padding = 1;
        label-full-padding = 1;
      };
    })

    # Power profile - using speedometer icon
    (lib.optionalAttrs showPower {
      "module/power" = {
        type = "custom/script";
        exec = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl get";
        interval = 5;
        format = "<label>";
        label = "󰓅 %output%";
        label-background = "\${colors.background-alt}";
        label-foreground = "\${colors.accent2}";
        label-padding = 1;
      };
    })

    # Brightness - using sun icon
    # Use custom/script with brightnessctl instead of internal/backlight
    # because AMD GPU backlight reports actual_brightness at ~97% max
    # while brightnessctl reports the requested brightness (100%)
    (lib.optionalAttrs showBacklight {
      "module/backlight" = {
        type = "custom/script";
        exec = "${pkgs.brightnessctl}/bin/brightnessctl -m | ${pkgs.coreutils}/bin/cut -d',' -f4 | ${pkgs.coreutils}/bin/tr -d '%'";
        interval = 2;
        format = "<label>";
        label = "󰃠 %output%%";
        label-foreground = "\${colors.foreground}";
        label-background = "\${colors.background-alt}";
        label-padding = 1;
      };
    })

    # IP address - using globe icon
    (lib.optionalAttrs showIp {
      "module/ip" = {
        type = "custom/script";
        exec = "${pkgs.iproute2}/bin/ip -4 route get 1.1.1.1 | ${pkgs.gawk}/bin/awk '{for (i=1; i<=NF; i++) if ($i==\"src\") {print $(i+1); exit}}'";
        interval = 5;
        format = "<label>";
        label = "󰖟 %output%";
        label-background = "\${colors.background-alt}";
        label-foreground = "\${colors.accent}";
        label-padding = 1;
      };
    })
  ];
}
