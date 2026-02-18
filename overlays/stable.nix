# Stable nixpkgs overlay
# Provides pkgs.stable for packages that break on unstable
{ inputs }:
_final: prev: {
  stable = import inputs.nixpkgs-stable {
    inherit (prev.stdenv.hostPlatform) system;
    config.allowUnfree = true;
    config.allowAliases = false;
  };
}
