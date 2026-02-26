# Terminal Configuration
# Complete terminal ecosystem setup
#
# Modules:
#   alacritty.nix - Modern GPU-accelerated terminal with vi mode
#   tmux/         - Terminal multiplexer with enhanced keybindings and plugins
#   yazi/         - Modern file manager with theme integration

{
  imports = [
    ./alacritty.nix
    ./tmux
    ./yazi
  ];
}
