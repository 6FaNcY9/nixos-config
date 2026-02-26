# Development shells — enter with `nix develop .#<name>` or `just <name>`.
#
# Shells:
#   default   — General Nix maintenance work (pre-commit, nix tools, just)
#   web       — Frontend development (Node.js, pnpm, yarn, TypeScript, Bun, PostgreSQL)
#   rust      — Rust development (rustc, cargo, rust-analyzer, cargo-watch, cargo-edit)
#   go        — Go development (go, gopls, delve, go-tools)
#   agents    — AI tools (OpenCode, Node.js, pnpm, Bun)
#   nix-debug — Nixpkgs inspection (nix-tree, nix-diff, nix-index, manix, nvd, nixd, etc.)
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
        # Nix maintenance shell — general flake/config work.
        # Entered automatically by direnv.
        default = {
          name = "nixos-config";
          motd = "{202}nixos-config{reset} devshell\n";
          packages = flakeToolsPackages;
        };

        # ── Web ────────────────────────────────────────────
        # Frontend development shell (Node, TypeScript, Bun, PostgreSQL).
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
        # Rust development shell (compiler, cargo, LSP, watch, edit).
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
        # Go development shell (compiler, LSP, debugger, tools).
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
        # AI development tools shell (OpenCode, Node.js runtime).
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
        # Nixpkgs ecosystem inspection shell.
        # Tools: nix-tree (explore closures), nix-diff (compare derivations),
        #        nix-index (fast package search), manix (docs), nvd (generation diff),
        #        nurl (fetch helpers), nixpkgs-review (PR testing), nixd (LSP).
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
                p.nix-tree # Explore Nix store closures interactively
                p.nix-diff # Compare derivations
                p.nix-output-monitor # Pretty build output
                p.nix-index # Fast package search (nix-locate)
                p.manix # Nix documentation search
                p.nvd # NixOS generation diff
                p.nurl # URL fetcher helpers
                p.nix-prefetch-github # GitHub fetcher
                p.nixpkgs-review # PR review tool
                p.nixd # Nix language server
              ]
            );
        };
      };
    };
}
