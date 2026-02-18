{ lib, nixpkgsConfig, ... }:
{
  # Ensure CLI nix commands can evaluate unfree packages too.
  # Generate config.nix from the same nixpkgsConfig used in flake.nix
  xdg.configFile."nixpkgs/config.nix".text = lib.generators.toPretty { } nixpkgsConfig;
}
