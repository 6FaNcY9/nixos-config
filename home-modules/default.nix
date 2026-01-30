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
    ./shell.nix
    ./git.nix
    ./starship.nix
    ./alacritty.nix
    ./nixpkgs.nix

    # Desktop environment
    ./i3.nix
    ./polybar.nix
    ./rofi-scripts.nix
    ./rofi-theme.nix
    ./firefox.nix
    ./desktop-services.nix
    ./xfce-session.nix
    ./clipboard.nix
    ./opencode.nix

    # Optional/disabled
    ./i3blocks.nix
    ./lnav.nix
    ./nixvim.nix
  ];
}
