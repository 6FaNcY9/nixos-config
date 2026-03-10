# Shell feature modules
# Imports: git (delta, difftastic), fish (atuin, fzf, direnv, zoxide), starship (base16 prompt),
#          bat (syntax-highlighted cat), eza (modern ls with icons + git status)
{
  imports = [
    ./git.nix
    ./fish.nix
    ./starship.nix
    ./bat.nix
    ./eza.nix
  ];
}
