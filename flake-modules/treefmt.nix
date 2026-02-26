# Treefmt configuration — unified code formatting.
#
# Formatters:
#   nixfmt — Nix code formatter (official Nixpkgs formatter)
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
