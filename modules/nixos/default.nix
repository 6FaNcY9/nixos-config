{...}: {
  imports = [
    ./core.nix
    ./secrets.nix
    ./storage.nix
    ./services.nix
    ./desktop.nix
    ./stylix-nixos.nix
  ];
}
