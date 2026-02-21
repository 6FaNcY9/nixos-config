# Core modules (always enabled)
# No options - these are fundamental system requirements
{ ... }:
{
  imports = [
    ./nix.nix
    ./memory.nix
    ./oomd.nix
    ./boot.nix
    ./networking.nix
    ./users.nix
    ./programs.nix
    ./packages.nix
    ./fonts.nix
    ./system.nix
  ];
}
