{inputs, ...}: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    inputs.sops-nix.homeManagerModules.sops
    inputs.stylix.homeModules.stylix
    ../shared-modules/stylix-common.nix
    ./devices.nix
    ./firefox.nix
    ./i3.nix
    ./i3blocks.nix
    ./lnav.nix
    ./nixvim.nix
    ./polybar.nix
    ./profiles.nix
    ./secrets.nix
  ];
}
