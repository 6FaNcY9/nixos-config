# Home Manager composition root for user: vino
#
# Boundary: This file is the composition root.
# It wires together the import graph, injects shared module arguments,
# and sets the minimal user identity (username, home directory, state version).
# User-specific implementation details live in user.nix.
# Host-specific overrides live in hosts/<hostname>.nix.
{
  lib,
  config,
  pkgs,
  osConfig ? null,
  username,
  hostname,
  ...
}:
let
  hostName = if osConfig != null then osConfig.networking.hostName else hostname; # Fallback when using standalone home-manager
  hostModulePath = ./hosts/${hostName}.nix;
  hostModules = lib.optionals (builtins.pathExists hostModulePath) [ hostModulePath ];
in
{
  imports = [
    ../../home-modules/default.nix
    ./user.nix
  ]
  ++ hostModules;

  # Inject shared arguments into all home-modules via _module.args.
  # Retained intentionally: cfgLib, palette, c, workspaces, stylixFonts, hostname
  # are active consumers in desktop theming, i3, polybar, and rofi modules.
  _module.args =
    let
      stylixFonts = lib.attrByPath [ "stylix" "fonts" ] {
        sansSerif.name = "Sans";
        monospace.name = "Monospace";
      } config;
    in
    {
      inherit (config.theme) palette;
      inherit (config) workspaces;
      c = config.theme.colors;
      inherit stylixFonts;
      hostname = hostName;
      cfgLib = import ../../lib {
        inherit lib pkgs;
      };
    };

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.11";
  };
}
