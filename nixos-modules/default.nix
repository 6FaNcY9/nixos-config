{ inputs, ... }:
{
  imports = [
    # External modules
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops

    # Shared modules
    ../shared-modules/stylix-common.nix

    # ===== OLD MODULES (keep during migration) =====
    ./core.nix
    # ./storage.nix # MIGRATED to features/storage/{boot,swap,btrfs,snapper}.nix
    # ./services.nix # MIGRATED to features/services/{auto-update,openssh,trezord}.nix
    # ./secrets.nix # MIGRATED to features/security/secrets.nix
    # ./monitoring.nix # MIGRATED to features/services/monitoring.nix
    # ./backup.nix # MIGRATED to features/services/backup.nix
    # ./tailscale.nix # MIGRATED to features/services/tailscale.nix

    # Role system (desktop, laptop, server)
    ./roles

    # Desktop environment
    # ./desktop.nix # MIGRATED to features/desktop/i3-xfce.nix
    # ./stylix-nixos.nix # MIGRATED to features/theme/stylix.nix

    # Home Manager integration
    ./home-manager.nix

    # ===== NEW MODULES (being built) =====
    ./core # Core system modules (empty placeholders)
    ./features # Optional feature modules (empty templates)
    ./profiles # Feature bundles (will add in Phase 3)
  ];
}
