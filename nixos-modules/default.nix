{ inputs, ... }:
{
  imports = [
    # External modules
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops

    # Shared modules
    ../shared-modules/stylix-common.nix

    # ===== OLD MODULES (deprecated, will be deleted in Phase 4) =====
    # ./core.nix # MIGRATED to core/{nix,users,networking,programs,packages,fonts,system}.nix
    # ./storage.nix # MIGRATED to features/storage/{boot,swap,btrfs,snapper}.nix
    # ./services.nix # MIGRATED to features/services/{auto-update,openssh,trezord}.nix
    # ./secrets.nix # MIGRATED to features/security/secrets.nix
    # ./monitoring.nix # MIGRATED to features/services/monitoring.nix
    # ./backup.nix # MIGRATED to features/services/backup.nix
    # ./tailscale.nix # MIGRATED to features/services/tailscale.nix
    # ./desktop.nix # MIGRATED to features/desktop/i3-xfce.nix
    # ./stylix-nixos.nix # MIGRATED to features/theme/stylix.nix
    # ./roles # MIGRATED to features/security/{server-hardening,desktop-hardening}.nix

    # Home Manager integration
    ./home-manager.nix

    # ===== NEW MODULES (active) =====
    ./core # Core system modules (nix, users, networking, programs, packages, fonts)
    ./features # Optional feature modules
    ./profiles # Feature bundles
  ];
}
