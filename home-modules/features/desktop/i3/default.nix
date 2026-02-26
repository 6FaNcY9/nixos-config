# i3 window manager module - Entry point for i3 configuration
# Imports: config.nix (colors, gaps, floating rules)
#          keybindings.nix (all keyboard shortcuts)
#          autostart.nix (startup programs)
#          workspace.nix (workspace assignments)

{
  lib,
  i3Pkg,
  config,
  ...
}:
let
  cfg = config.features.desktop.i3;
in
{
  imports = [
    ./config.nix
    ./keybindings.nix
    ./autostart.nix
    ./workspace.nix
  ];

  options.features.desktop.i3 = {
    enable = lib.mkEnableOption "i3 window manager with custom configuration";
  };

  config = lib.mkIf cfg.enable {
    xsession = {
      enable = true;
      windowManager.i3 = {
        enable = true;
        package = i3Pkg;
      };
    };
  };
}
