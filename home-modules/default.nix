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

    # Shell & CLI
    ./package-managers.nix
    ./shell.nix
    ./git.nix
    ./starship.nix
    ./alacritty.nix
    ./nixpkgs.nix

    # Desktop environment
    ./desktop/i3
    ./desktop/polybar
    ./rofi/default.nix
    ./firefox.nix
    ./desktop-services.nix
    ./xfce-session.nix
    ./clipboard.nix

    # Editor configuration
    ./editor/nixvim

    # Tmux
    ./tmux.nix
  ];
}
