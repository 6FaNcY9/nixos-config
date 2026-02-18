# Overlays composition
# Imports and combines all overlays
{ inputs }:
{
  default =
    final: prev:
    # Compose all overlays
    (import ./stable.nix { inherit inputs; } final prev)
    // (import ./custom-packages.nix { inherit inputs; } final prev);
}
