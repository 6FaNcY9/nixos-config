# Nixpkgs overlays — custom package overrides and builds.
#
# Exports:
#   - opencode: patched with --linker=isolated for Bun
#   - mistral-vibe: Official flake package (uv2nix Python wrapper)
#   - tree-sitter-cli: Pinned to 0.26.5 for nixvim compatibility
{ inputs }:
{
  default = import ./custom-packages.nix { inherit inputs; };
}
