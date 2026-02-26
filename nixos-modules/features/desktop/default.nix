# Desktop Features Aggregator
#
# Imports all desktop environment and window manager configurations.
# Currently includes: i3-xfce (i3 window manager with XFCE components).
{ ... }:
{
  imports = [
    ./i3-xfce.nix
  ];
}
