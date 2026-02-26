# Hardware Features Aggregator
#
# Imports hardware-specific configurations for different device types.
# Currently includes: laptop (power management, bluetooth, fingerprint, etc.).
{ ... }:
{
  imports = [
    ./laptop.nix
  ];
}
