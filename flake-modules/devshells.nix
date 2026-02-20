# Development shells — enter with `nix develop .#<name>` or `just <name>`.
{
  perSystem =
    {
      pkgs,
      commonDevPackages,
      flakeToolsPackages,
      opencodePkg,
      ...
    }:
    let
      # Common packages for project-specific shells (not the default).
      projectShellPackages = commonDevPackages ++ [
        pkgs.just
      ];
    in
    {
      devshells = {
        # ── Default ────────────────────────────────────────
        # Nix maintenance shell — entered automatically by direnv.
        default = {
          name = "nixos-config";
          motd = "{202}nixos-config{reset} devshell\n";
          packages = flakeToolsPackages;
        };

        # ── Web ────────────────────────────────────────────
        web = {
          name = "web";
          motd = "{202}web{reset} devshell\n";
          packages =
            projectShellPackages
            ++ (
              let
                p = pkgs;
              in
              [
                p.nodejs
                p.pnpm
                p.yarn
                p.typescript
                p.bun
                p.postgresql
              ]
            );
        };

        # ── Rust ───────────────────────────────────────────
        rust = {
          name = "rust";
          motd = "{202}rust{reset} devshell\n";
          packages =
            projectShellPackages
            ++ (
              let
                p = pkgs;
              in
              [
                p.rustc
                p.cargo
                p.rust-analyzer
                p.cargo-watch
                p.cargo-edit
              ]
            );
        };

        # ── Go ─────────────────────────────────────────────
        go = {
          name = "go";
          motd = "{202}go{reset} devshell\n";
          packages =
            projectShellPackages
            ++ (
              let
                p = pkgs;
              in
              [
                p.go
                p.gopls
                p.delve
                p.go-tools
                p.gotools
              ]
            );
        };

        # ── Agents ─────────────────────────────────────────
        agents = {
          name = "agents";
          motd = "{202}agents{reset} devshell\n";
          packages =
            projectShellPackages
            ++ [
              opencodePkg
            ]
            ++ (
              let
                p = pkgs;
              in
              [
                p.nodejs
                p.pnpm
                p.bun
              ]
            );
        };

        # ── Nix Debug ──────────────────────────────────────
        nix-debug = {
          name = "nix-debug";
          motd = "{202}nix-debug{reset} devshell\n";
          packages =
            projectShellPackages
            ++ (
              let
                p = pkgs;
              in
              [
                p.nix-tree
                p.nix-diff
                p.nix-output-monitor
                p.nix-index # Fast package search (nix-locate)
                p.manix # Nix documentation search
                p.nvd # NixOS generation diff
                p.nurl
                p.nix-prefetch-github
                p.nixpkgs-review
                p.nixd
              ]
            );
          commands = [
            {
              name = "nix-locate";
              help = "Search for packages by file path (e.g., nix-locate bin/hello)";
              category = "search";
            }
            {
              name = "manix";
              help = "Search Nix documentation (e.g., manix mkIf)";
              category = "search";
            }
            {
              name = "nvd";
              help = "Diff NixOS generations (e.g., nvd diff /run/booted-system /run/current-system)";
              category = "comparison";
            }
            {
              name = "nix-tree";
              help = "Browse dependency tree interactively";
              category = "inspection";
            }
            {
              name = "nix-diff";
              help = "Diff two derivations to see what changed";
              category = "comparison";
            }
          ];
        };
      };
    };
}
