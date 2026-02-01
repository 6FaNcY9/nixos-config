{inputs, ...}: {
  imports = [
    # External modules
    inputs.nixvim.homeModules.nixvim
    inputs.sops-nix.homeManagerModules.sops
    inputs.stylix.homeModules.stylix

    # Shared modules
    ../shared-modules/stylix-common.nix
    ../shared-modules/workspaces.nix
    ../shared-modules/palette.nix

    # Core modules
    ./profiles.nix
    ./devices.nix
    ./secrets.nix
    ./user-services.nix
    ./nixpkgs.nix

    # Shell & CLI environment
    ./features/shell

    # Desktop environment
    ./features/desktop/i3
    ./features/desktop/polybar
    ./rofi/rofi.nix
    ./firefox.nix
    ./desktop-services.nix
    ./xfce-session.nix
    ./clipboard.nix

    # Editor configuration
    ./features/editor/nixvim
  ];
}
