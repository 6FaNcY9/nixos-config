# Security feature modules
{ ... }:
{
  imports = [
    ./secrets.nix
    # Will add: hardening.nix in Phase 3
  ];
}
