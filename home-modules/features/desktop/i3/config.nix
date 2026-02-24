{
  lib,
  c,
  palette,
  ...
}:
{
  xsession.windowManager.i3.config = {
    modifier = "Mod4";
    terminal = "alacritty";
    menu = "rofi -show drun";

    gaps = {
      inner = 8;
      outer = 0;
      smartGaps = true;
      smartBorders = "on";
    };

    window = {
      border = 2;
      titlebar = false;
    };

    colors = lib.mkDefault {
      focused = {
        border = palette.warn;
        background = c.base01;
        text = c.base07;
        indicator = palette.warn;
        childBorder = palette.warn;
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
        border = palette.danger;
        background = c.base00;
        text = c.base07;
        indicator = palette.danger;
        childBorder = palette.danger;
      };
    };

    workspaceAutoBackAndForth = true;
    bars = lib.mkDefault [ ];

    window.commands = [
      {
        command = "floating enable";
        criteria = {
          class = "Pavucontrol";
        };
      }
      {
        command = "floating enable";
        criteria = {
          class = "Nm-connection-editor";
        };
      }
      {
        command = "floating enable";
        criteria = {
          class = "Gsimplecal";
        };
      }
      {
        command = "floating enable";
        criteria = {
          class = "Blueman-manager";
        };
      }
      {
        command = "floating enable, resize set 800 600";
        criteria = {
          class = "Thunar";
          title = "File Operation Progress";
        };
      }
    ];

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
}
