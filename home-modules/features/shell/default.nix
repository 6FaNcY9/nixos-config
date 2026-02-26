# Shell feature modules
# Imports: git (delta, difftastic), fish (atuin, fzf, direnv, zoxide), starship (base16 prompt), vibe (mistral AI agent)
#
{
  imports = [
    ./git.nix
    ./fish.nix
    ./starship.nix
    ./vibe.nix
  ];
}
