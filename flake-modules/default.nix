# Flake modules entry point — imports all perSystem modules.
#
# Sub-modules:
#   _common.nix   — Shared helpers and package sets
#   apps.nix      — Flake apps (nix run .#<name>)
#   checks.nix    — Build checks (NixOS + Home Manager)
#   devshells.nix — Development shells (nix develop .#<name>)
#   packages.nix  — Custom packages and scripts
#   pre-commit.nix — Git pre-commit hooks
#   services.nix  — Process-compose dev services
#   treefmt.nix   — Code formatting (nix fmt)

{
  imports = [
    ./_common.nix
    ./apps.nix
    ./checks.nix
    ./devshells.nix
    ./packages.nix
    ./pre-commit.nix
    ./services.nix
    ./treefmt.nix
  ];
}
