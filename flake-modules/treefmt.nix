# Treefmt configuration — unified code formatting.
#
# Formatters:
#   nixfmt — Nix code formatter (official Nixpkgs formatter)
#
# Note: shfmt is handled by the standalone pre-commit hook (see pre-commit.nix)
# to avoid option conflicts with treefmt's shfmt configuration.
#
# Usage:
#   nix fmt          — Format all files
#   treefmt --check  — Check formatting without modifying

_: {
  perSystem =
    { config, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        flakeCheck = true;
      };

      formatter = config.treefmt.build.wrapper;
    };
}
