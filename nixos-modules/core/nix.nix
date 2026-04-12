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
        "@wheel" # wheel users can add substituters, use cachix, set --option substituters
      ];
      allowed-users = [
        "root"
        "@wheel"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      sandbox = true; # Lock sandbox on — prevents per-build override by trusted-users
      auto-optimise-store = false; # Disabled: runs inline on every build (adds latency). Run manually: sudo nix-store --optimise
      warn-dirty = true;
      keep-outputs = true; # Preserve intermediate build artifacts for faster incremental rebuilds
      keep-derivations = true;
      # Optimize builds
      max-jobs = "auto";
      cores = 0;

      # Binary caches for faster builds (community pattern)
      substituters = [
        # cache.nixos.org is added automatically by NixOS — not listed here to avoid duplicates
        "https://nix-community.cachix.org"
        "https://vino-nixos-config.cachix.org" # Personal binary cache
      ];
      trusted-public-keys = [
        # cache.nixos.org key is added automatically by NixOS — not listed here to avoid duplicates
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "vino-nixos-config.cachix.org-1:8LFVkzmO/+crLWO0Q3bqWOOamVjScT3v1/PCHPiTiUU=" # Personal cache key
      ];

      # Skip global flake registry lookup — self-contained with pinned nixpkgs
      flake-registry = "";
      # Prevent flakes from overriding trusted-users/substituters via nixConfig
      accept-flake-config = false;
    };

    # Use nh's cleaner to avoid double GC scheduling.
    gc.automatic = lib.mkDefault false;

    # Store optimisation: scheduled weekly (avoids inline latency during builds)
    optimise = {
      automatic = true;
      dates = "weekly";
    };

  };

  # Pin nixpkgs in registry and NIX_PATH so both `nix run nixpkgs#...` and
  # legacy `nix-shell '<nixpkgs>'` / third-party scripts use the pinned revision.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  # Allow unfree, catch deprecated aliases, wire overlays (keeps pkgs.stable available as fallback).
  nixpkgs = {
    config = nixpkgsConfig;
    overlays = [ inputs.self.overlays.default ];
  };
}
