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
