# Service feature modules
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
