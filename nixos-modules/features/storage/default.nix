# Storage Features Aggregator
#
# Imports storage and filesystem-related configurations including bootloader,
# swap, BTRFS maintenance (fstrim/scrub), and snapshot management (Snapper).
{ ... }:
{
  imports = [
    ./boot.nix
    ./swap.nix
    ./btrfs.nix
    ./snapper.nix
  ];
}
