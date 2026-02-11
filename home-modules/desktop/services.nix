# Desktop session services: dunst, picom, flameshot, network-manager-applet
{
  lib,
  pkgs,
  config,
  palette,
  ...
}: {
  config = lib.mkIf config.profiles.desktop {
    services = {
      network-manager-applet.enable = true;
      dunst = {
        enable = true;
        settings = {
          global = {
            font = lib.mkForce "IosevkaTerm Nerd Font 10";
            frame_width = lib.mkForce 2;
            frame_color = lib.mkForce palette.accent;
            corner_radius = lib.mkForce 10;
            offset = lib.mkForce "10x40";
            origin = lib.mkForce "top-right";
            separator_color = lib.mkForce "frame";
            padding = lib.mkForce 8;
            horizontal_padding = lib.mkForce 12;
            icon_position = lib.mkForce "left";
            max_icon_size = lib.mkForce 32;

            show_indicators = lib.mkForce true;
            history_length = lib.mkForce 20;
          };
          urgency_low = {
            background = lib.mkForce palette.bg;
            foreground = lib.mkForce palette.text;
            frame_color = lib.mkForce palette.muted;
            timeout = lib.mkForce 5;
          };
          urgency_normal = {
            background = lib.mkForce palette.bg;
            foreground = lib.mkForce palette.text;
            frame_color = lib.mkForce palette.accent;
            timeout = lib.mkForce 10;
          };
          urgency_critical = {
            background = lib.mkForce palette.bg;
            foreground = lib.mkForce palette.text;
            frame_color = lib.mkForce palette.danger;
            timeout = lib.mkForce 0;
          };
        };
      };
      picom = {
        enable = true;
        backend = "glx";

        # Subtle transparency for depth
        activeOpacity = 1.0;
        inactiveOpacity = 0.98;
        menuOpacity = 0.99;

        # Fade animations
        fade = false;
        fadeDelta = 4;
        fadeSteps = [0.03 0.03];

        # Subtle shadows
        shadow = false;
        shadowOffsets = [(-4) (-4)];
        shadowOpacity = 0.25;
        shadowExclude = [
          "name = 'Notification'"
          "class_g = 'Conky'"
          "class_g = 'Polybar'"
          "_GTK_FRAME_EXTENTS@:c"
        ];

        vSync = true;

        settings = {
          # Rounded corners on windows
          corner-radius = 8;
          rounded-corners-exclude = [
            "window_type = 'dock'"
            "window_type = 'desktop'"
            "class_g = 'Polybar'"
          ];
          shadow-radius = 8;
          shadow-color = palette.bg;
        };
      };

      flameshot = {
        enable = true;
        package = pkgs.flameshot;
        settings = {
          General = {
            uiColor = palette.bgAlt;
            drawColor = palette.accent;
            showSidePanelButton = true;
            showDesktopNotification = false;
            disabledTrayIcon = false;
          };
          Shortcuts = {
            TYPE_COPY = "Return";
            TYPE_SAVE = "Ctrl+S";
          };
        };
      };
    };
  };
}
