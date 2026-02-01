# Shell environment configuration
# Aggregates all shell-related modules: fish, starship, alacritty, git
{
  imports = [
    ./fish.nix
    ./starship.nix
    ./alacritty.nix
    ./git.nix
  ];
}
