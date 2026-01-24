{inputs, ...}: {
  imports = [
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops
    ../shared-modules/stylix-common.nix
    ./core.nix
    ./roles.nix
    ./profiles.nix
    ./roles-laptop.nix
    ./roles-server.nix
    ./server-base.nix
    ./secrets.nix
    ./storage.nix
    ./services.nix
    ./desktop.nix
    ./stylix-nixos.nix
    ./home-manager.nix
  ];
}
