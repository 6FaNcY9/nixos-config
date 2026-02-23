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

    # ===== OLD MODULES (keep during migration) =====
    # Categories
    ./desktop
    ./editor
    ./shell
    ./terminal

    # Infrastructure (flat)
    ./profiles.nix

    # ===== NEW MODULES (future) =====
    ./core
    ./features
  ];
}
