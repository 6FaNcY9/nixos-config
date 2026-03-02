# Shell feature modules
# Imports: git (delta, difftastic), fish (atuin, fzf, direnv, zoxide), starship (base16 prompt)
#
{
  imports = [
    ./git.nix
    ./fish.nix
    ./starship.nix
  ];
}
