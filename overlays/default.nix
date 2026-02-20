# Overlays composition
# Imports and combines all overlays
{ inputs }:
{
  default = import ./custom-packages.nix { inherit inputs; };
}
