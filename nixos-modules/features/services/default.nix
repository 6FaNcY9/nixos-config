# Service Features Aggregator
#
# Imports all optional system services including VPN (Tailscale),
# monitoring (Prometheus/Grafana), auto-updates, SSH server, and hardware daemons.
{ ... }:
{
  imports = [
    ./cloudflared.nix
    ./tailscale.nix
    ./monitoring.nix
    ./auto-update.nix
    ./openssh.nix
    ./trezord.nix
  ];
}
