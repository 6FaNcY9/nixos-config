# Nixpkgs configuration for standalone nix/nixpkgs commands
# Writes ~/.config/nixpkgs/config.nix so that standalone nix-* commands (nix-env, nix-shell, etc.)
# outside of NixOS flake context can evaluate unfree packages and use the same nixpkgs config.
#
{ lib, nixpkgsConfig, ... }:
{
  xdg.configFile."nixpkgs/config.nix".text = lib.generators.toPretty { } nixpkgsConfig;
}
