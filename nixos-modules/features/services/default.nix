# Service feature modules
{ ... }:
{
  imports = [
    ./tailscale.nix
    ./backup.nix
    ./monitoring.nix
  ];
}
