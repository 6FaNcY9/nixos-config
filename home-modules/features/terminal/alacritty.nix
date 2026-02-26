# Alacritty Terminal Emulator Configuration
# Modern, GPU-accelerated terminal with vi mode for text selection and search
#
# Features:
#   - Vi mode for vim-like text selection (C-S-Space to toggle)
#   - Search forward/backward in scrollback (C-S-F / C-S-B)
#   - 10k line scrollback history
#   - Dynamic padding and minimal decorations
{ lib, config, ... }:
let
  cfg = config.features.terminal.alacritty;
in
{
  options.features.terminal.alacritty = {
    enable = lib.mkEnableOption "alacritty terminal emulator";
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        window = {
          dynamic_padding = true;
          decorations = "none";
        };

        scrolling.history = 10000;

        keyboard.bindings = [
          # Vi mode: Enable vim-like text selection and navigation in terminal scrollback
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
  };
}
