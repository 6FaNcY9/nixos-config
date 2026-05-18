# Shared modules aggregator
# Cross-layer modules consumed by both NixOS and Home Manager.
# Stable residents: stylix-common.nix, workspaces.nix, palette.nix
#
# NOTE: This aggregator is a taxonomy scaffold. The stable aggregators
# (nixos-modules/default.nix, home-modules/default.nix) continue to
# import shared modules by explicit path. This file exists so that
# shared-modules/ is a proper importable module directory and the
# taxonomy is complete. Downstream consumers may import this file
# directly once the composition-root wave lands.
{ ... }:
{
  imports = [
    ./stylix-common.nix
    ./workspaces.nix
    ./palette.nix
  ];
}
