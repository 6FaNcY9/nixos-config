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
            ++ (with pkgs; [
              nodejs
              pnpm
              yarn
              typescript
              bun
              postgresql
            ]);
        };

        # ── Rust ───────────────────────────────────────────
        rust = {
          name = "rust";
          motd = "{202}rust{reset} devshell\n";
          packages =
            projectShellPackages
            ++ (with pkgs; [
              rustc
              cargo
              rust-analyzer
              cargo-watch
              cargo-edit
            ]);
        };

        # ── Go ─────────────────────────────────────────────
        go = {
          name = "go";
          motd = "{202}go{reset} devshell\n";
          packages =
            projectShellPackages
            ++ (with pkgs; [
              go
              gopls
              delve
              go-tools
              gotools
            ]);
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
            ++ (with pkgs; [
              nodejs
              pnpm
              bun
            ]);
        };

        # ── Nix Debug ──────────────────────────────────────
        nix-debug = {
          name = "nix-debug";
          motd = "{202}nix-debug{reset} devshell\n";
          packages =
            projectShellPackages
            ++ (with pkgs; [
              nix-tree
              nix-diff
              nix-output-monitor
              manix
              nurl
              nix-prefetch-github
              nixpkgs-review
              nixd
            ]);
        };
      };
    };
}
