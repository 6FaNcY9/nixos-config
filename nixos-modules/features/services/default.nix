# Service feature modules
{ ... }:
{
  imports = [
    ./tailscale.nix
    ./backup.nix
    # Will add: monitoring.nix in subsequent tasks
  ];
}
