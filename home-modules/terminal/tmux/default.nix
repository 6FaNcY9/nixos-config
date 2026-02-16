{ ... }:
{
  imports = [
    ./keybindings.nix
    ./plugins.nix
    ./statusbar.nix
  ];

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
}
