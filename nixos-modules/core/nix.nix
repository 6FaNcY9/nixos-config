# Core: Nix configuration
# Always enabled (no option)
{
  lib,
  inputs,
  nixpkgsConfig,
  ...
}:
{
  # Nix settings (flakes, binary caches, GC)
  nix = {
    settings = {
      trusted-users = [
        "root"
        "@wheel"
      ]; # Allow running nix commands without sudo
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = false; # Disabled: runs inline on every build (adds latency). Run manually: sudo nix-store --optimise
      warn-dirty = true;
      # Optimize builds
      max-jobs = "auto";
      cores = 0;

      # Binary caches for faster builds (community pattern)
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://vino-nixos-config.cachix.org" # Personal binary cache
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "vino-nixos-config.cachix.org-1:8LFVkzmO/+crLWO0Q3bqWOOamVjScT3v1/PCHPiTiUU=" # Personal cache key
      ];
    };

    # Use nh's cleaner to avoid double GC scheduling.
    gc.automatic = lib.mkDefault false;

    # Store optimisation disabled (run manually: sudo nix-store --optimise)
    optimise.automatic = false;
  };

  # Pin nixpkgs for legacy commands and for `nix run nixpkgs#...`
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # Allow unfree, catch deprecated aliases, wire overlays (keeps pkgs.stable available as fallback).
  nixpkgs = {
    config = nixpkgsConfig;
    overlays = [ inputs.self.overlays.default ];
  };
}
