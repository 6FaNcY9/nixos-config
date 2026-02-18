# Service feature modules
{ ... }:
{
  imports = [
    ./tailscale.nix
    # Will add: backup.nix, monitoring.nix in subsequent tasks
  ];
}
