{...}: {
  imports = [
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
  ];
}
