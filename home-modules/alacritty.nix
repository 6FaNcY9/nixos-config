# Alacritty terminal emulator configuration
{...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        dynamic_padding = true;
        decorations = "none";
      };

      scrolling.history = 10000;

      keyboard.bindings = [
        # Enter/leave Vi mode (selection/search)
        {
          key = "Space";
          mods = "Control|Shift";
          action = "ToggleViMode";
        }

        # Search prompts (works in vi mode)
        {
          key = "F";
          mods = "Control|Shift";
          action = "SearchForward";
        }
        {
          key = "B";
          mods = "Control|Shift";
          action = "SearchBackward";
        }

        # Copy/Paste helpers
        {
          key = "C";
          mods = "Control|Shift";
          action = "Copy";
        }
        {
          key = "V";
          mods = "Control|Shift";
          action = "Paste";
        }
      ];
    };
  };
}
