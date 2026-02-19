# Storage feature modules
{ ... }:
{
  imports = [
    ./boot.nix
    ./swap.nix
    ./btrfs.nix
    ./snapper.nix
  ];
}
