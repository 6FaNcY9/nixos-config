# Desktop Features Aggregator
#
# Imports all desktop environment and window manager configurations.
# Currently includes: i3 with greetd + tuigreet.
{ ... }:
{
  imports = [
    ./i3.nix
  ];
}
