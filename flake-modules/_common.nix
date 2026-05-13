# Shared helpers and package sets used across all perSystem modules.
{ pkgsFor, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    let
      cfgLib = import ../lib { inherit (pkgs) lib; };
      overlayPkgs = pkgsFor system;

      # ── Package sets ──────────────────────────────────────
      # Essential CLI tools included in every devshell.
      commonDevPackages =
        let
          p = pkgs;
        in
        [
          p.git
          p.gh
          p.jq
          p.curl
          p.ripgrep
          p.fd
          p.fzf
          p.bat
          p.eza
          p.tree
        ];

      # Pre-commit + Nix tooling for the default (maintenance) shell.
      maintenancePackages =
        let
          p = pkgs;
        in
        [
          p.pre-commit
          p.nix
        ];

      # Everything needed for the default devshell.
      flakeToolsPackages =
        maintenancePackages
        ++ commonDevPackages
        ++ [
          pkgs.just
          pkgs.nix-tree # Interactive Nix closure explorer
        ];

      # ── Helpers ───────────────────────────────────────────
      opencodePkg = overlayPkgs.opencode;
      opencodeBunPkg = overlayPkgs."opencode-bun";

      # Create a flake app from a shell script.
      # Usage: mkApp "update" [pkgs.git pkgs.nix] "Update flake" ''#!/usr/bin/env bash\necho "hi"''
      mkApp = name: runtimeInputs: description: text: {
        type = "app";
        program = pkgs.lib.getExe (
          pkgs.writeShellApplication {
            inherit name text runtimeInputs;
            meta = {
              inherit description;
            };
          }
        );
      };
    in
    {
      _module.args = {
        inherit
          cfgLib
          commonDevPackages
          flakeToolsPackages
          mkApp
          opencodePkg
          opencodeBunPkg
          ;
      };
    };
}
