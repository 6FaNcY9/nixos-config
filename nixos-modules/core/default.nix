# Core modules (always enabled)
# No options - these are fundamental system requirements
{ ... }:
{
  imports = [
    ./nix.nix
    ./oomd.nix
    ./networking.nix
    ./users.nix
    ./programs.nix
    ./packages.nix
    ./fonts.nix
  ];
}
