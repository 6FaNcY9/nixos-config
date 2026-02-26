# Security Features Aggregator
#
# Imports security-related modules including secrets management (sops-nix),
# server hardening (fail2ban, sysctls), and desktop hardening (polkit, firewall).
{ ... }:
{
  imports = [
    ./secrets.nix
    ./server-hardening.nix
    ./desktop-hardening.nix
  ];
}
