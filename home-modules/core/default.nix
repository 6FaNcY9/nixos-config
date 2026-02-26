# Core Home Manager modules
# Imports: device identifiers, nixpkgs config, package manager XDG paths, sops-nix secrets
#
{
  imports = [
    ./devices.nix
    ./nixpkgs.nix
    ./package-managers.nix
    ./secrets.nix
  ];
}
