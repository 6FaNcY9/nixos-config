# Nixpkgs overlays — explicit aggregator composing intent-based overlay files.
#
# Overlay files:
#   additions.nix     — packages not present in nixpkgs upstream
#   modifications.nix — overrides of packages that already exist in nixpkgs
#
# Exports (via default overlay):
#   - hermes-agent: Nous Research self-improving AI agent (upstream flake)
#   - mistral-vibe: Official flake package (uv2nix Python wrapper)
#   - opencode-bun: Bun runtime wrapper for opencode-ai@latest (impure, fetches on first run)
#   - tree-sitter-cli: Pinned to 0.26.5 for nixvim compatibility
{ inputs }:
{
  # default: composed overlay used by flake.nix pkgsFor.
  # Applies additions then modifications so modifications can reference added packages.
  default =
    final: prev:
    let
      additions = import ./additions.nix { inherit inputs; } final prev;
      modifications = import ./modifications.nix { inherit inputs; } final prev;
    in
    additions // modifications;
}
