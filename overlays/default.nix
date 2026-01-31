{inputs}: {
  default = _final: prev: {
    # Stable packages available as pkgs.stable.* (fallback when unstable breaks)
    stable = import inputs.nixpkgs-stable {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };
}
