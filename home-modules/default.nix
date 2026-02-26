# Home Manager module entry point
# Imports: nixvim, sops-nix, stylix (external), shared-modules, profiles.nix, ./core, ./features
#
{ inputs, ... }:
{
  imports = [
    # External modules
    inputs.nixvim.homeModules.nixvim
    inputs.sops-nix.homeManagerModules.sops
    inputs.stylix.homeModules.stylix

    # Shared modules
    ../shared-modules/stylix-common.nix
    ../shared-modules/workspaces.nix
    ../shared-modules/palette.nix

    # Infrastructure
    ./profiles.nix
    # Modules
    ./core
    ./features
  ];
}
