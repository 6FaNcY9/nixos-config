{
  lib,
  i3Pkg,
  config,
  ...
}:
# Module: features/desktop/i3
# Purpose: i3 window manager configuration
#
# Structure:
#   - default.nix: Main aggregator (this file)
#   - config.nix: Window colors, fonts, bars, window rules
#   - keybindings.nix: Keyboard shortcuts (uses lib helpers)
#   - autostart.nix: Startup applications
#   - workspace.nix: Workspace assignments
#
# Dependencies:
#   - i3 package
#   - Stylix for theming (color palette injection)
#   - cfgLib (workspace and directional keybinding helpers)
#
# Usage:
#   Automatically loaded via home-modules/default.nix
#   Configured via _module.args (c, palette, workspaces)
#
{
  imports = [
    ./config.nix
    ./keybindings.nix
    ./autostart.nix
    ./workspace.nix
  ];

  config = lib.mkIf config.profiles.desktop {
    xsession = {
      enable = true;
      windowManager.i3 = {
        enable = true;
        package = i3Pkg;
      };
    };
  };
}
