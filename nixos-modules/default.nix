{inputs, ...}: {
  imports = [
    # External modules
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops

    # Shared modules
    ../shared-modules/stylix-common.nix

    # Core system modules
    ./core.nix
    ./storage.nix
    ./services.nix
    ./secrets.nix
    ./security # Centralized security settings (sysctl, future: AppArmor, USBGuard)
    ./monitoring.nix
    ./backup # Now a directory with options.nix, power-check.nix, restic.nix
    ./stylix-nixos.nix

    # Roles (conditional behavior)
    ./roles

    # Desktop environment
    ./desktop.nix
    ./home-manager.nix
  ];
}
