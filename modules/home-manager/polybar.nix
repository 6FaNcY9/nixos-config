{
  config,
  pkgs,
  lib,
  palette,
  hostname,
  workspaces,
  ...
}: let
  wsIconAttrs = lib.listToAttrs (
    lib.imap0 (index: workspace: {
      name = "ws-icon-${toString index}";
      value = "${workspace.name};${workspace.icon}";
    })
    workspaces
  );
in {
  # Enable polybar via Home Manager
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      i3Support = true;
      pulseSupport = true;
      iwSupport = true;
    };

    # Let Stylix theme polybar if enabled
    # (Stylix will inject colors/fonts automatically when stylix.targets.polybar.enable = true)
    script = ''
      ${pkgs.procps}/bin/pkill -x polybar || true
      ${config.services.polybar.package}/bin/polybar --reload top &
    '';

    settings = {
      "colors" = {
        background = "${palette.bg}";
        background-alt = "${palette.bgAlt}";
        foreground = "${palette.text}";
        accent = "${palette.accent}";
        accent2 = "${palette.accent2}";
        warn = "${palette.warn}";
        danger = "${palette.danger}";
        muted = "${palette.muted}";
      };

      "bar/top" = {
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

        modules-left = "i3";
        modules-center = "xwindow";
        modules-right = "host network pulseaudio battery backlight power clock spacer-tray tray";
        cursor-click = "pointer";
        enable-ipc = true;
        wm-restack = "i3";
      };

      "module/i3" =
        {
          type = "internal/i3";
          format = "<label-state>";
          index-sort = true;
          pin-workspaces = true;
          strip-wsnumbers = false;
          ws-icon-default = "";
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

      "module/host" = {
        type = "custom/text";
        format = "  ${hostname}";
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

      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        format-volume = "<label-volume>";
        label-volume = " %percentage%%";
        label-volume-background = "\${colors.background-alt}";
        label-volume-foreground = "\${colors.foreground}";
        label-volume-padding = 1;
        label-muted = " mute";
        label-muted-foreground = "\${colors.danger}";
        label-muted-background = "\${colors.background-alt}";
        label-muted-padding = 1;
      };

      "module/battery" = {
        type = "internal/battery";
        battery = "BAT1";
        full-at = 98;
        format-charging = "<label-charging>";
        format-discharging = "<label-discharging>";
        format-full = "<label-full>";
        label-charging = " %percentage%%";
        label-discharging = " %percentage%%";
        label-full = " 100%";
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

      "module/power" = {
        type = "custom/script";
        exec = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl get";
        interval = 5;
        format = "<label>";
        label = " %output%";
        label-background = "\${colors.background-alt}";
        label-foreground = "\${colors.accent2}";
        label-padding = 1;
      };

      "module/network" = {
        type = "internal/network";
        interface-type = "wireless";
        interval = 5;
        format-connected = "<label-connected>";
        label-connected = "  %essid%";
        label-connected-background = "\${colors.background-alt}";
        label-connected-foreground = "\${colors.accent}";
        format-disconnected = "<label-disconnected>";
        label-disconnected = " offline";
        label-disconnected-background = "\${colors.background-alt}";
        label-disconnected-foreground = "\${colors.danger}";
        label-connected-padding = 1;
        label-disconnected-padding = 1;
      };

      "module/clock" = {
        type = "internal/date";
        interval = 5;
        date = "%H:%M";
        format = "<label>";
        label = "%{A1:${pkgs.gsimplecal}/bin/gsimplecal &:}  %date%%{A}";
        label-foreground = "\${colors.accent2}";
        label-background = "\${colors.background-alt}";
        label-padding = 1;
      };

      "module/backlight" = {
        type = "internal/backlight";
        card = "amdgpu_bl1";
        format = "<label>";
        label = " %percentage%%";
        label-foreground = "\${colors.foreground}";
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
    };
  };

  # Optional: let Stylix theme polybar
  #stylix.targets.polybar.enable = lib.mkDefault true;
}
