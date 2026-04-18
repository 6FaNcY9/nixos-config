# Desktop session services module
# Notification daemon (dunst), compositor (picom), screenshot tool (flameshot), system tray applets
# - Dunst provides desktop notifications with palette-colored urgency levels
# - Picom provides compositing with subtle transparency and rounded corners
# - Flameshot provides screenshot capabilities with annotation tools
{
  lib,
  config,
  palette,
  ...
}:
let
  cfg = config.features.desktop.services;
in
{
  options.features.desktop.services = {
    enable = lib.mkEnableOption "desktop session services (dunst, picom, flameshot, network-manager-applet)";
  };

  config = lib.mkIf cfg.enable {
    services = {
      network-manager-applet.enable = true;
      blueman-applet.enable = true;
      dunst = {
        enable = true;
        settings = {
          global = {
            frame_width = 2;
            frame_color = palette.accent;
            corner_radius = 10;
            offset = "10x40";
            origin = "top-right";
            separator_color = "frame";
            padding = 8;
            horizontal_padding = 12;
            icon_position = "left";
            max_icon_size = 32;

            show_indicators = true;
            history_length = 20;
          };
          urgency_low = {
            background = palette.bg;
            foreground = palette.text;
            frame_color = palette.muted;
            timeout = 5;
          };
          urgency_normal = {
            background = palette.bg;
            foreground = palette.text;
            frame_color = palette.accent;
            timeout = 10;
          };
          urgency_critical = {
            background = palette.bg;
            foreground = palette.text;
            frame_color = palette.danger;
            timeout = 0;
          };
        };
      };
      picom = {
        enable = true;
        backend = "glx";

        # Subtle inactive window dimming for visual depth without distraction
        activeOpacity = 1.0;
        inactiveOpacity = 1.0;
        menuOpacity = 1.0;

        # Fade animations
        fade = false;
        fadeDelta = 4;
        fadeSteps = [
          0.03
          0.03
        ];

        # Subtle shadows
        shadow = false;
        shadowOffsets = [
          (-4)
          (-4)
        ];
        shadowOpacity = 0.25;
        shadowExclude = [
          "name = 'Notification'"
          "class_g = 'Conky'"
          "class_g = 'Polybar'"
          "_GTK_FRAME_EXTENTS@:c"
        ];

        vSync = true;

        settings = {
          # Rounded corners (8px radius) for modern aesthetics
          # 10 = 8 inner radius + 2px border width, ensures concentric rounding with no corner artifacts
          corner-radius = 10;
          # Round the outer border edge too, preventing clipped corner pixels on i3 borders
          round-borders = 1;
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
