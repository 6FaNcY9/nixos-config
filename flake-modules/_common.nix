# Shared helpers and package sets used across all perSystem modules.
{
  perSystem =
    {
      pkgs,
      inputs',
      ...
    }:
    let
      cfgLib = import ../lib { inherit pkgs; };

      # ── Package sets ──────────────────────────────────────
      # Essential CLI tools included in every devshell.
      commonDevPackages = with pkgs; [
        git
        gh
        jq
        curl
        ripgrep
        fd
        fzf
        bat
        eza
        tree
      ];

      # Pre-commit + Nix tooling for the default (maintenance) shell.
      maintenancePackages = with pkgs; [
        pre-commit
        nix
      ];

      # Everything needed for the default devshell.
      flakeToolsPackages =
        maintenancePackages
        ++ commonDevPackages
        ++ [
          pkgs.just
        ];

      # ── Helpers ───────────────────────────────────────────
      opencodePkg = inputs'.opencode.packages.default;

      # mkApp name runtimeInputs description text
      # description is for documentation only (not used at runtime).
      mkApp = name: runtimeInputs: _description: text: {
        type = "app";
        program = pkgs.lib.getExe (
          pkgs.writeShellApplication {
            inherit name text runtimeInputs;
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
          ;
      };
    };
}
