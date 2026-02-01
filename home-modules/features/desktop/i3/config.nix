{
  lib,
  c,
  ...
}: {
  xsession.windowManager.i3.config = {
    modifier = "Mod4";
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
      commands = [
        # Floating backup progress terminal
        {
          criteria = {
            title = "Backup Progress";
            class = "Alacritty";
          };
          command = "floating enable, resize set 900 600, move position center";
        }
      ];
    };

    colors = lib.mkDefault {
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
    bars = lib.mkDefault [];

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
