# Service Features Aggregator
#
# Imports all optional system services including VPN (Tailscale), backup (Restic),
# monitoring (Prometheus/Grafana), auto-updates, SSH server, and hardware daemons.
{ ... }:
{
  imports = [
    ./tailscale.nix
    ./backup.nix
    ./monitoring.nix
    ./auto-update.nix
    ./openssh.nix
    ./trezord.nix
  ];
}
