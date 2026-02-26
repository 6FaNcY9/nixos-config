# Tmux Configuration
# Terminal multiplexer with enhanced keybindings and plugin ecosystem
#
# Sub-modules:
#   keybindings.nix - Custom prefix (C-Space) and vim-style navigation
#   plugins.nix     - Plugin ecosystem (sensible, which-key, battery, yank, resurrect, continuum)
#   statusbar.nix   - Enhanced status line with battery, load, hostname, datetime

{ lib, config, ... }:
let
  cfg = config.features.terminal.tmux;
in
{
  options.features.terminal.tmux = {
    enable = lib.mkEnableOption "tmux terminal multiplexer";
  };

  imports = [
    ./keybindings.nix
    ./plugins.nix
    ./statusbar.nix
  ];

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;

      # HM-typed options (safe defaults)
      mouse = true;
      keyMode = "vi";
      historyLimit = 50000;
      terminal = "tmux-256color";
      escapeTime = 0;
      baseIndex = 1;
    };
  };
}
