# Security feature modules
{ ... }:
{
  imports = [
    ./secrets.nix
    ./server-hardening.nix
    ./desktop-hardening.nix
  ];
}
