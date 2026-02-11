{inputs, ...}: {
  imports = [
    # External modules
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops

    # Shared modules
    ../shared-modules/stylix-common.nix

    # Core system
    ./core.nix
    ./storage.nix
    ./services.nix
    ./secrets.nix
    ./monitoring.nix
    ./backup.nix
    ./tailscale.nix

    # Role system (desktop, laptop, server)
    ./roles

    # Desktop environment
    ./desktop.nix
    ./stylix-nixos.nix

    # Home Manager integration
    ./home-manager.nix
  ];
}
