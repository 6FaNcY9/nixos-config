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
    ./devices.nix
    ./nixpkgs.nix
    ./package-managers.nix
    ./profiles.nix
    ./secrets.nix

    # ===== NEW MODULES (being built) =====
    ./core # Core user modules (empty)
    ./features # Optional user features (empty)
  ];
}
